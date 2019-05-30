require 'excon'

class CustomWizard::Authorization
  include ActiveModel::SerializerSupport

  NGROK_URL = ''

  attr_accessor :authorized,
                :service,
                :auth_type,
                :auth_url,
                :token_url,
                :client_id,
                :client_secret,
                :auth_params,
                :access_token,
                :refresh_token,
                :token_expires_at,
                :token_refresh_at,
                :code,
                :username,
                :password

  def initialize(service, params)
    @service = service
    data = params.is_a?(String) ? ::JSON.parse(params) : params

    data.each do |k, v|
      self.send "#{k}=", v if self.respond_to?(k)
    end
  end

  def authorized
    @authorized ||= @access_token && @token_expires_at.to_datetime > Time.now
  end

  def self.set(service, data)
    model = self.get(service) || {}

    data.each do |k, v|
      model.send "#{k}=", v if model.respond_to?(k)
    end

    PluginStore.set("custom_wizard_#{service}", 'authorization', model.as_json)

    self.get(service)
  end

  def self.get(service)
    data = PluginStore.get("custom_wizard_#{service}", 'authorization')
    self.new(service, data)
  end

  def self.list
    PluginStoreRow.where("plugin_name LIKE 'custom_wizard_%' AND key = 'authorization'")
      .map { |record| self.new(record['plugin_name'].split('_').last, record['value']) }
  end

  def self.get_header_authorization_string(service)
    protocol = authentication_protocol(service)
    raise Discourse::InvalidParameters.new(:service) unless protocol.present?
    raise Discourse::InvalidParameters.new(:protocol) unless [BASIC_AUTH, OAUTH2_AUTH].include? protocol

    if protocol = BASIC_AUTH
      username = username(service)
      raise Discourse::InvalidParameters.new(:username) unless username.present?
      password = password(service)
      raise Discourse::InvalidParameters.new(:password) unless password.present?
      authorization_string = (username + ":" + password).chomp
      "Basic #{Base64.strict_encode64(authorization_string)}"
    else
      # must be OAUTH2
      access_token = access_token(service)
      raise Discourse::InvalidParameters.new(access_token) unless access_token.present?
      "Bearer #{access_token}"
    end
  end

  def self.get_token(service)
    authorization = CustomWizard::Authorization.get(service)

    body = {
      client_id: authorization.client_id,
      client_secret: authorization.client_secret,
      code: authorization.code,
      grant_type: 'authorization_code',
      redirect_uri: Discourse.base_url + "/admin/wizards/apis/#{service}/redirect"
    }

    result = Excon.post(
      authorization.token_url,
      :headers => {
        "Content-Type" => "application/x-www-form-urlencoded"
      },
      :body => URI.encode_www_form(body)
    )

    self.handle_token_result(service, result)
  end

  def self.refresh_token(service)
    authorization = CustomWizard::Authorization.get(service)

    body = {
      grant_type: 'refresh_token',
      refresh_token: authorization.refresh_token
    }

    authorization_string = authorization.client_id + ':' + authorization.client_secret

    result = Excon.post(
      authorization.token_url,
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

    access_token = data['access_token']
    refresh_token = data['refresh_token']
    expires_at = Time.now + data['expires_in'].seconds
    refresh_at = expires_at.to_time - 2.hours

    opts = {
      service: service
    }

    Jobs.enqueue_at(refresh_at, :refresh_api_access_token, opts)

    CustomWizard::Authorization.set(service,
      access_token: access_token,
      refresh_token: refresh_token,
      token_expires_at: expires_at,
      token_refresh_at: refresh_at
    )
  end
end
