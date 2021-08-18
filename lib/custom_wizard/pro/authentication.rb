class CustomWizard::ProAuthentication
  include ActiveModel::Serialization

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

  private

  def api_key_db_key
    "api_key"
  end

  def api_client_id_db_key
    "api_client_id"
  end

  def keys_db_key
    "keys"
  end

  def get_api_key
    raw = PluginStore.get(CustomWizard::Pro.namespace, api_key_db_key)
    OpenStruct.new(
      key: raw && raw['key'],
      auth_by: raw && raw['auth_by'],
      auth_at: raw && raw['auth_at']
    )
  end

  def set_api_key(key, user_id)
    PluginStore.set(CustomWizard::Pro.namespace, api_key_db_key,
      key: key,
      auth_by: user_id,
      auth_at: Time.now
    )
  end

  def remove
    PluginStore.remove(CustomWizard::Pro.namespace, api_key_db_key)
  end

  def get_client_id
    PluginStore.get(CustomWizard::Pro.namespace, api_client_id_db_key)
  end

  def set_client_id
    client_id = SecureRandom.hex(32)
    PluginStore.set(CustomWizard::Pro.namespace, api_client_id_db_key, client_id)
    client_id
  end

  def set_keys(request_id, user_id, rsa, nonce)
    PluginStore.set(CustomWizard::Pro.namespace, "#{keys_db_key}_#{request_id}",
      user_id: user_id,
      pem: rsa.export,
      nonce: nonce
    )
  end

  def get_keys(request_id)
    raw = PluginStore.get(CustomWizard::Pro.namespace, "#{keys_db_key}_#{request_id}")
    OpenStruct.new(
      user_id: raw && raw['user_id'],
      pem: raw && raw['pem'],
      nonce: raw && raw['nonce']
    )
  end

  def delete_keys(request_id)
    PluginStore.remove(CustomWizard::Pro.namespace, "#{keys_db_key}_#{request_id}")
  end
end