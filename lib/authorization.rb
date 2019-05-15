require 'excon'

class CustomWizard::Authorization

  BASIC_AUTH = 'basic_authentication'
  OAUTH2_AUTH  = 'OAuth2_authentication'

  def self.authentication_protocol(service)
    PluginStore.get(service, 'authentication_protocol') || {}
  end

  def self.set_authentication_protocol(service, protocol)
  # TODO: make error more informative
    raise Discourse::InvalidParameters.new(:protocol) unless [BASIC_AUTH, OAUTH2_AUTH].include? protocol
      PluginStore.set(service, 'authentication_protocol', protocol)
  end

  def self.access_token(service)
    PluginStore.get(service, 'access_token') || {}
  end

  def self.set_access_token(service, data)
    PluginStore.set(service, 'access_token', data)
  end

  def self.refresh_token (service)
    PluginStore.get(service, 'refresh_token')
  end

  def self.set_refresh_token(service, token)
    PluginStore.set(service, 'refresh_token', token)
  end

  def self.code(service)
    PluginStore.get(service,'code')
  end

  def self.set_code(service, code)
    PluginStore.set(service, 'code', code)
  end

  def self.username(service)
    PluginStore.get(service,'username')
  end

  def self.set_username(service, username)
    PluginStore.set(service, 'username', username)
  end

  def self.password(service)
    PluginStore.get(service,'password')
  end

  def self.set_password(service, password)
    PluginStore.set(service, 'password', password)
  end

  def self.client_id(service)
    PluginStore.get(service,'client_id')
  end

  def self.set_client_id(service, client_id)
    PluginStore.set(service, 'client_id', client_id)
  end

  def self.client_secret(service)
    PluginStore.get(service,'client_secret')
  end

  def self.set_client_secret(service, client_secret)
    PluginStore.set(service, 'client_secret', client_secret)
  end

  def self.url(service)
    PluginStore.get(service,'url')
  end

  def self.set_url(service, url)
    PluginStore.set(service, 'url', url)
  end

  def self.get_header_authorization_string(service)
    # TODO: make error more informative, raise error if service not defined
    protocol = authentication_protocol(service)
    raise Discourse::InvalidParameters.new(:service) unless protocol.present?
    raise Discourse::InvalidParameters.new(:protocol) unless [BASIC_AUTH, OAUTH2_AUTH].include? protocol

    if protocol = BASIC_AUTH
      # TODO: improve error reporting
      username = username(service)
      raise Discourse::InvalidParameters.new(:username) unless username.present?
      password = password(service)
      raise Discourse::InvalidParameters.new(:password) unless password.present?
      authorization_string = (username + ":" + password).chomp
      "Basic #{Base64.strict_encode64(authorization_string)}"
    else
    # must be OAUTH2
    # TODO: make error more informative, raise error if there is no recorded access token
      raise Discourse::InvalidParameters unless access_token[:token].present?
      "Bearer #{access_token[:token]}"
    end
  end

  def self.get_access_token(service)
    body = {
      client_id: CustomWizard::Authorization.client_id(service),
      client_secret: CustomWizard::Authorization.client_secret(service),
      code: CustomWizard::Authorization.code(service),
      grant_type: 'authorization_code',
      redirect_uri: (Rails.env.development? ? CustomWizard::NGROK_URL : Discourse.base_url) + '/custom_wizard/authorization/callback'
    }

    result = Excon.post(
      CustomWizard::Authorization.url(service),
      :headers => {
        "Content-Type" => "application/x-www-form-urlencoded"
      },
      :body => URI.encode_www_form(body)
    )

    self.handle_token_result(service, result)
  end

  def self.refresh_access_token(service)
    body = {
      grant_type: 'refresh_token',
      refresh_token: CustomWizard::Authorization.refresh_token
    }

    authorization_string = CustomWizard::Authorization.client_id(service) + ':' + CustomWizard::Authorization.client_secret(service)

    result = Excon.post(
      CustomWizard::Authorization.url(service),
      :headers => {
        "Content-Type" => "application/x-www-form-urlencoded",
        "Authorization" => "Basic #{Base64.strict_encode64(authorization_string)}"
      },
      :body => URI.encode_www_form(body)
    )

    self.handle_token_result(service, result)
  end

  def self.handle_token_result(service, result)
    data = JSON.parse(result.body)
    return false if (data['error'])

    token = data['access_token']
    expires_at = Time.now + data['expires_in'].seconds
    refresh_at = expires_at.to_time - 2.hours

    Jobs.enqueue_at(refresh_at, :refresh_api_access_token)

    CustomWizard::Authorization.set_access_token(
      service: service,
      token: token,
      expires_at: expires_at,
      refresh_at: refresh_at
    )

    CustomWizard::Authorization.set_refresh_token(service, data['refresh_token'])
  end

  def self.authorized(service)
    CustomWizard::Authorization.access_token[service, :token] &&
    CustomWizard::Authorization.access_token[service, :expires_at].to_datetime > Time.now
  end
end
