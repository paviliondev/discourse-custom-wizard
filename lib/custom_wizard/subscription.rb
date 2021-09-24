# frozen_string_literal: true

class CustomWizard::Subscription
  include ActiveModel::Serialization

  attr_accessor :authentication,
                :subscription

  def initialize
    @authentication = CustomWizard::Subscription::Authentication.new(get_authentication)
    @subscription = CustomWizard::Subscription::Subscription.new(get_subscription)
  end

  def authorized?
    @authentication.active?
  end

  def subscribed?
    @subscription.active?
  end

  def server
    "test.thepavilion.io"
  end

  def subscription_type
    "stripe"
  end

  def client_name
    "custom-wizard"
  end

  def scope
    "discourse-subscription-server:user_subscription"
  end

  def update
    if @authentication.active?
      response = Excon.get(
        "https://#{server}/subscription-server/user-subscriptions/#{subscription_type}/#{client_name}",
        headers: {
          "User-Api-Key" => @authentication.api_key
        }
      )

      if response.status == 200
        begin
          data = JSON.parse(response.body).deep_symbolize_keys
        rescue JSON::ParserError
          return false
        end

        return false unless data && data.is_a?(Hash)
        subscriptions = data[:subscriptions]

        if subscriptions.present? && type = subscriptions.first[:price_nickname]
          @subscription = set_subscription(type)
          return true
        end
      end
    end

    destroy_subscription
    false
  end

  def destroy_subscription
    if remove_subscription
      @subscription = CustomWizard::Subscription::Subscription.new(get_subscription)
      !@subscription.active?
    else
      false
    end
  end

  def authentication_url(user_id, request_id)
    keys = @authentication.generate_keys(user_id, request_id)
    params = {
      public_key: keys.public_key,
      nonce: keys.nonce,
      client_id: @authentication.client_id,
      auth_redirect: "#{Discourse.base_url}/admin/wizards/subscription/authorize/callback",
      application_name: SiteSetting.title,
      scopes: scope
    }

    uri = URI.parse("https://#{server}/user-api-key/new")
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end

  def authentication_response(request_id, payload)
    data = @authentication.decrypt_payload(request_id, payload)
    return false unless data.is_a?(Hash) && data[:key] && data[:user_id]

    api_key = data[:key]
    user_id = data[:user_id]
    user = User.find(user_id)

    if user&.admin
      @authentication = set_authentication(api_key, user.id)
      true
    else
      false
    end
  end

  def destroy_authentication
    if remove_authentication
      @authentication = CustomWizard::Subscription::Authentication.new(get_authentication)
      !@authentication.active?
    else
      false
    end
  end

  def self.subscribed?
    self.new.subscribed?
  end

  def self.authorized?
    self.new.authorized?
  end

  def self.update
    self.new.update
  end

  def self.namespace
    "custom_wizard_subscription"
  end

  private

  def subscription_db_key
    "subscription"
  end

  def authentication_db_key
    "authentication"
  end

  def get_subscription
    raw = PluginStore.get(self.class.namespace, subscription_db_key)

    if raw.present?
      OpenStruct.new(
        type: raw['type'],
        updated_at: raw['updated_at']
      )
    end
  end

  def remove_subscription
    PluginStore.remove(self.class.namespace, subscription_db_key)
  end

  def set_subscription(type)
    PluginStore.set(CustomWizard::Subscription.namespace, subscription_db_key, type: type, updated_at: Time.now)
    CustomWizard::Subscription::Subscription.new(get_subscription)
  end

  def get_authentication
    raw = PluginStore.get(self.class.namespace, authentication_db_key)
    OpenStruct.new(
      key: raw && raw['key'],
      auth_by: raw && raw['auth_by'],
      auth_at: raw && raw['auth_at']
    )
  end

  def set_authentication(key, user_id)
    PluginStore.set(self.class.namespace, authentication_db_key,
      key: key,
      auth_by: user_id,
      auth_at: Time.now
    )
    CustomWizard::Subscription::Authentication.new(get_authentication)
  end

  def remove_authentication
    PluginStore.remove(self.class.namespace, authentication_db_key)
    get_authentication
  end
end
