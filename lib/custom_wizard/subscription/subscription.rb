# frozen_string_literal: true
class CustomWizard::Subscription::Subscription
  include ActiveModel::Serialization

  attr_reader :type,
              :updated_at

  STANDARD ||= "standard"
  BUSINESS ||= "business"
  FEATURES ||= {
    wizard: {
      permitted: STANDARD
    },
    step: {
      index: STANDARD,
      condition: STANDARD,
      required_data: BUSINESS,
      permitted_params: BUSINESS
    },
    field: {
      index: STANDARD,
      condition: STANDARD,
      prefill: STANDARD,
      content: STANDARD,
      validations: STANDARD,
      type: {
        tag: STANDARD,
        category: STANDARD,
        group: STANDARD,
        composer: STANDARD,
        composer_preview: STANDARD
      }
    },
    action: {
      type: {
        send_message: STANDARD,
        watch_categories: STANDARD,
        add_to_group: STANDARD,
        send_to_api: BUSINESS,
        create_category: BUSINESS,
        create_group: BUSINESS
      }
    },
    custom_field: {
      klass: {
        group: BUSINESS,
        category: BUSINESS
      },
      type: {
        json: STANDARD
      }
    },
    api: {}
  }

  def initialize(subscription)
    if subscription
      @type = subscription.type
      @updated_at = subscription.updated_at
    end
  end

  def active?
    self.class.types.include?(type) && updated_recently
  end

  def updated_recently
    updated_at.to_datetime > (Time.zone.now - 2.hours).to_datetime
  end

  def has_required_type?(t)
    t && type && type_index(type) >= type_index(t)
  end

  def type_index(t)
    self.class.types.index(t)
  end

  def determine_feature_subscription_type(klass, attribute, value)
    return BUSINESS if klass.to_sym === :api
    type = FEATURES.dig(*[klass.to_sym, attribute.to_sym])

    if type.is_a?(Hash) && value.present?
      type = type[value.to_sym]
    else
      type
    end
  end

  def self.types
    [STANDARD, BUSINESS]
  end
end
