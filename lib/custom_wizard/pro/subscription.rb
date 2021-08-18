class CustomWizard::ProSubscription
  include ActiveModel::Serialization

  attr_reader :type,
              :updated_at

  def initialize
    raw = get

    if raw
      @type = raw['type']
      @updated_at = raw['updated_at']
    end
  end

  def types
    %w(community business)
  end

  def active?
    types.include?(type) && updated_at.to_datetime > (Date.today - 15.minutes).to_datetime
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

  def destroy
    remove
  end

  private

  def key
    "custom_wizard_pro_subscription"
  end

  def set(type)
    PluginStore.set(CustomWizard::Pro.namespace, key, type: type, updated_at: Time.now)
  end

  def get
    PluginStore.get(CustomWizard::Pro.namespace, key)
  end

  def remove
    PluginStore.remove(CustomWizard::Pro.namespace, key)
  end
end