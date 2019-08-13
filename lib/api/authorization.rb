require 'excon'

class CustomWizard::Api::Authorization
  include ActiveModel::SerializerSupport

  attr_accessor :api_name,
                :authorized,
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

  def initialize(api_name, data={})
    @api_name = api_name

    data.each do |k, v|
      self.send "#{k}=", v if self.respond_to?(k)
    end
  end

  def authorized
    @authorized ||= @access_token && @token_expires_at.to_datetime > Time.now
  end

  def self.set(api_name, new_data = {})

    api_name = api_name.underscore

    data = self.get(api_name, data_only: true) || {}

    new_data.each do |k, v|
      data[k.to_sym] = v
    end

    PluginStore.set("custom_wizard_api_#{api_name}", 'authorization', data)

    self.get(api_name)
  end

  def self.get(api_name, opts = {})
    api_name = api_name.underscore

    if data = PluginStore.get("custom_wizard_api_#{api_name}", 'authorization')
      if opts[:data_only]
        data
      else
        self.new(api_name, data)
      end
    else
      nil
    end
  end

  def self.remove(api_name)
    PluginStore.remove("custom_wizard_api_#{api_name}", "authorization")
  end

  def self.authorization_string(name)
    auth = CustomWizard::Api::Authorization.get(name)
    raise Discourse::InvalidParameters.new(:name) unless auth.present?

    if auth.auth_type === "basic"
      raise Discourse::InvalidParameters.new(:username) unless auth.username.present?
      raise Discourse::InvalidParameters.new(:password) unless auth.password.present?
      "Basic #{Base64.strict_encode64((auth.username + ":" + auth.password).chomp)}"
    elsif ['oauth_3', 'oauth_2'].include?(auth.auth_type)
      raise Discourse::InvalidParameters.new(auth.access_token) unless auth.access_token.present?
      "Bearer #{auth.access_token}"
    else
      nil
    end
  end

  def self.get_token(name, opts = {})
    authorization = CustomWizard::Api::Authorization.get(name)
    type = authorization.auth_type

    body = {}

    if opts[:refresh] && type === 'oauth_3'
      body['grant_type'] = 'refresh_token'
    elsif type === 'oauth_2'
      body['grant_type'] = 'client_credentials'
    elsif type === 'oauth_3'
      body['grant_type'] = 'authorization_code'
    end

    unless opts[:refresh]
      body['client_id'] = authorization.client_id
      body['client_secret'] = authorization.client_secret
    end

    if type === 'oauth_3'
      body['code'] = authorization.code
      body['redirect_uri'] = Discourse.base_url + "/admin/wizards/apis/#{name}/redirect"
    end

    connection = Excon.new(
      authorization.token_url,
      :headers => {
        "Content-Type" => "application/x-www-form-urlencoded"
      },
      :method => 'GET',
      :query => URI.encode_www_form(body)
    )
    begin
      result = connection.request()
      log_params = {time: Time.now, user_id: 0, status: 'SUCCESS', url: authorization.token_url, error: ""}
      CustomWizard::Api::LogEntry.set(name, log_params)
    rescue SystemCallError => e
      log_params = {time: Time.now, user_id: 0, status: 'FAILURE', url: authorization.token_url, error: "Token refresh request failed: #{e.inspect}"}
      CustomWizard::Api::LogEntry.set(name, log_params)
    end

    self.handle_token_result(name, result)
  end

  def self.handle_token_result(name, result)
    result_data = JSON.parse(result.body)

    if result_data['error']
      return result_data
    end

    data = {}

    data['access_token'] = result_data['access_token']
    data['refresh_token'] = result_data['refresh_token'] if result_data['refresh_token']
    data['token_type'] = result_data['token_type'] if result_data['token_type']

    if result_data['expires_in']
      data['token_expires_at'] = Time.now + result_data['expires_in'].seconds
      data['token_refresh_at'] = data['token_expires_at'].to_time - 10.minutes

      opts = {
        name: name
      }

      Jobs.enqueue_at(data['token_refresh_at'], :refresh_api_access_token, opts)
    end

    CustomWizard::Api::Authorization.set(name, data)
  end
end
