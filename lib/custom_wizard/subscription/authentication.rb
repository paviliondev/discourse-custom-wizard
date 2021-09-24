# frozen_string_literal: true
class CustomWizard::Subscription::Authentication
  include ActiveModel::Serialization

  attr_reader :client_id,
              :auth_by,
              :auth_at,
              :api_key

  def initialize(auth)
    if auth
      @api_key = auth.key
      @auth_at = auth.auth_at
      @auth_by = auth.auth_by
    end

    @client_id = get_client_id || set_client_id
  end

  def active?
    @api_key.present?
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

  def get_keys(request_id)
    raw = PluginStore.get(CustomWizard::Subscription.namespace, "#{keys_db_key}_#{request_id}")
    OpenStruct.new(
      user_id: raw && raw['user_id'],
      pem: raw && raw['pem'],
      nonce: raw && raw['nonce']
    )
  end

  private

  def keys_db_key
    "keys"
  end

  def client_id_db_key
    "client_id"
  end

  def set_keys(request_id, user_id, rsa, nonce)
    PluginStore.set(CustomWizard::Subscription.namespace, "#{keys_db_key}_#{request_id}",
      user_id: user_id,
      pem: rsa.export,
      nonce: nonce
    )
  end

  def delete_keys(request_id)
    PluginStore.remove(CustomWizard::Subscription.namespace, "#{keys_db_key}_#{request_id}")
  end

  def get_client_id
    PluginStore.get(CustomWizard::Subscription.namespace, client_id_db_key)
  end

  def set_client_id
    client_id = SecureRandom.hex(32)
    PluginStore.set(CustomWizard::Subscription.namespace, client_id_db_key, client_id)
    client_id
  end
end
