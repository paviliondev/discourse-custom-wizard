require 'excon'

class CustomWizard::Api::Authorization
  include ActiveModel::SerializerSupport

  attr_accessor :authorized,
                :name,
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

  def initialize(name, data, opts = {})
    unless opts[:data_only]
      @name = name
    end

    if data = data.is_a?(String) ? ::JSON.parse(data) : data
      data.each do |k, v|
        self.send "#{k}=", v if self.respond_to?(k)
      end
    end
  end

  def authorized
    @authorized ||= @access_token && @token_expires_at.to_datetime > Time.now
  end

  def self.set(name, data = {})
    record = self.get(name, data_only: true)

    data.each do |k, v|
      record.send "#{k}=", v if record.respond_to?(k)
    end

    PluginStore.set("custom_wizard_api_#{name}", 'authorization', record.as_json)

    self.get(name)
  end

  def self.get(name, opts = {})
    data = PluginStore.get("custom_wizard_api_#{name}", 'authorization')
    self.new(name, data, opts)
  end

  def self.remove(name)
    PluginStore.remove("custom_wizard_api_#{name}", "authorization")
  end

  def self.get_header_authorization_string(name)
    protocol = authentication_protocol(name)
    raise Discourse::InvalidParameters.new(:name) unless protocol.present?
    raise Discourse::InvalidParameters.new(:protocol) unless [BASIC_AUTH, OAUTH2_AUTH].include? protocol

    if protocol = BASIC_AUTH
      username = username(name)
      raise Discourse::InvalidParameters.new(:username) unless username.present?
      password = password(name)
      raise Discourse::InvalidParameters.new(:password) unless password.present?
      authorization_string = (username + ":" + password).chomp
      "Basic #{Base64.strict_encode64(authorization_string)}"
    else
      # must be OAUTH2
      access_token = access_token(name)
      raise Discourse::InvalidParameters.new(access_token) unless access_token.present?
      "Bearer #{access_token}"
    end
  end

  def self.get_token(name)
    authorization = CustomWizard::Api::Authorization.get(name)

    body = {
      client_id: authorization.client_id,
      client_secret: authorization.client_secret,
      code: authorization.code,
      grant_type: 'authorization_code',
      redirect_uri: Discourse.base_url + "/admin/wizards/apis/#{name}/redirect"
    }

    result = Excon.post(
      authorization.token_url,
      :headers => {
        "Content-Type" => "application/x-www-form-urlencoded"
      },
      :body => URI.encode_www_form(body)
    )

    self.handle_token_result(name, result)
  end

  def self.refresh_token(name)
    authorization = CustomWizard::Api::Authorization.get(name)

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

    self.handle_token_result(name, result)
  end

  def self.handle_token_result(name, result)
    data = JSON.parse(result.body)

    return false if (data['error'])

    access_token = data['access_token']
    refresh_token = data['refresh_token']
    expires_at = Time.now + data['expires_in'].seconds
    refresh_at = expires_at.to_time - 2.hours

    opts = {
      name: name
    }

    Jobs.enqueue_at(refresh_at, :refresh_api_access_token, opts)

    CustomWizard::Api::Authorization.set(name,
      access_token: access_token,
      refresh_token: refresh_token,
      token_expires_at: expires_at,
      token_refresh_at: refresh_at
    )
  end
end
