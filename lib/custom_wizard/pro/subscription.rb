class CustomWizard::ProSubscription
  include ActiveModel::Serialization

  SUBSCRIPTION_SERVER ||= "test.thepavilion.io"
  SUBSCRIPTION_TYPE ||= "stripe"
  SCOPE ||= "discourse-subscription-server:user_subscription"
  CLIENT_NAME ||= "custom-wizard"
  SUBSCRIPTION_KEY ||= "custom_wizard_pro_subscription"
  UPDATE_DAY_BUFFER ||= 2
  TYPES ||= %w(community business)

  attr_reader :type,
              :updated_at

  def initialize
    raw = get

    if raw
      @type = raw['type']
      @updated_at = raw['updated_at']
    end
  end

  def active?
    TYPES.include?(type) && updated_at.to_datetime > (Date.today - UPDATE_DAY_BUFFER.days).to_datetime
  end

  def update(data)
    return false unless data && data.is_a?(Hash)
    subscriptions = data[:subscriptions]

    if subscriptions.present?
      subscription = subscriptions.first
      type = subscription[:price_nickname]

      set(type)
    end
  end

  def self.update
    @subscribed = nil
    auth = CustomWizard::ProAuthentication.new
    subscription = self.new

    if auth.active?
      response = Excon.get(
        "https://#{SUBSCRIPTION_SERVER}/subscription-server/user-subscriptions/#{SUBSCRIPTION_TYPE}/#{CLIENT_NAME}",
        headers: { "User-Api-Key" => auth.api_key }
      )

      if response.status == 200
        begin
          data = JSON.parse(response.body).deep_symbolize_keys
        rescue JSON::ParserError
          return false
        end

        return subscription.update(data)
      end
    end

    false
  end
  
  private
  
  def set(type)
    PluginStore.set(CustomWizard::Pro::NAMESPACE, SUBSCRIPTION_KEY, type: type, updated_at: Time.now)
  end

  def get
    PluginStore.get(CustomWizard::Pro::NAMESPACE, SUBSCRIPTION_KEY)
  end
end