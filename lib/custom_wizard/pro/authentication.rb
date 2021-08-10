class CustomWizard::ProAuthentication
  include ActiveModel::Serialization

  API_KEY ||= "api_key"
  API_CLIENT_ID ||= 'api_client_id'
  KEYS ||= "keys"

  attr_reader :client_id,
              :auth_by,
              :auth_at,
              :api_key

  def initialize
    api = get_api_key

    @api_key = api.key
    @auth_at = api.auth_at
    @auth_by = api.auth_by
    @client_id = get_client_id || set_client_id
  end

  def active?
    @api_key.present?
  end

  def update(data)
    api_key = data[:key]
    user_id = data[:user_id]
    user = User.find(user_id)

    if user&.admin
      set_api_key(api_key, user.id)
    else
      false
    end
  end

  def destroy
    remove
  end

  def self.destroy
    self.new.destroy
  end

  def generate_keys(user_id, request_id)
    rsa = OpenSSL::PKey::RSA.generate(2048) 
    nonce = SecureRandom.hex(32)
    set_keys(request_id, user_id, rsa, nonce)

    OpenStruct.new(nonce: nonce, public_key: rsa.public_key)
  end

  def decrypt_payload(request_id, payload)
    keys = get_keys(request_id)
    return false unless keys.present? && keys.pem
    delete_keys(request_id)

    rsa = OpenSSL::PKey::RSA.new(keys.pem)
    decrypted_payload = rsa.private_decrypt(Base64.decode64(payload))
    return false unless decrypted_payload.present?

    begin
      data = JSON.parse(decrypted_payload).symbolize_keys
    rescue JSON::ParserError
      return false
    end

    return false unless data[:nonce] == keys.nonce
    data[:user_id] = keys.user_id

    data
  end

  def self.generate_request(user_id, request_id)
    authentication = self.new
    keys = authentication.generate_keys(user_id, request_id)

    params = {
      public_key: keys.public_key,
      nonce: keys.nonce,
      client_id: authentication.client_id,
      auth_redirect: "#{Discourse.base_url}/admin/wizards/pro/authorize/callback",
      application_name: SiteSetting.title,
      scopes: CustomWizard::ProSubscription::SCOPE
    }

    uri = URI.parse("https://#{CustomWizard::ProSubscription::SUBSCRIPTION_SERVER}/user-api-key/new")
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end

  def self.handle_response(request_id, payload)
    authentication = self.new

    data = authentication.decrypt_payload(request_id, payload)
    return unless data.is_a?(Hash) && data[:key] && data[:user_id]

    authentication.update(data)
  end

  private

  def get_api_key
    raw = PluginStore.get(CustomWizard::Pro::NAMESPACE, API_KEY)
    OpenStruct.new(
      key: raw && raw['key'],
      auth_by: raw && raw['auth_by'],
      auth_at: raw && raw['auth_at']
    )
  end

  def set_api_key(key, user_id)
    PluginStore.set(CustomWizard::Pro::NAMESPACE, API_KEY,
      key: key,
      auth_by: user_id,
      auth_at: Time.now
    )
  end

  def remove
    PluginStore.remove(CustomWizard::Pro::NAMESPACE, API_KEY)
  end

  def get_client_id
    PluginStore.get(CustomWizard::Pro::NAMESPACE, API_CLIENT_ID)
  end

  def set_client_id
    client_id = SecureRandom.hex(32)
    PluginStore.set(CustomWizard::Pro::NAMESPACE, API_CLIENT_ID, client_id)
    client_id
  end

  def set_keys(request_id, user_id, rsa, nonce)
    PluginStore.set(CustomWizard::Pro::NAMESPACE, "#{KEYS}_#{request_id}",
      user_id: user_id,
      pem: rsa.export,
      nonce: nonce
    )
  end

  def get_keys(request_id)
    raw = PluginStore.get(CustomWizard::Pro::NAMESPACE, "#{KEYS}_#{request_id}")
    OpenStruct.new(
      user_id: raw && raw['user_id'],
      pem: raw && raw['pem'],
      nonce: raw && raw['nonce']
    )
  end

  def delete_keys(request_id)
    PluginStore.remove(CustomWizard::Pro::NAMESPACE, "#{KEYS}_#{request_id}")
  end
end