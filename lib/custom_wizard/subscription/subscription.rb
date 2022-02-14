# frozen_string_literal: true
class CustomWizard::Subscription::Subscription
  include ActiveModel::Serialization

  attr_reader :type,
              :updated_at

  NONE ||= "none"
  STANDARD ||= "standard"
  BUSINESS ||= "business"
  FEATURES ||= {
    actions: {
      type: {
        create_topic: NONE,
        update_profile: NONE,
        open_composer: NONE,
        route_to: NONE,
        send_message: STANDARD,
        watch_categories: STANDARD,
        add_to_group: STANDARD,
        send_to_api: BUSINESS,
        create_category: BUSINESS,
        create_group: BUSINESS
      }
    },
    custom_fields: {
      klass: {
        topic: NONE,
        post: NONE,
        group: BUSINESS,
        category: BUSINESS
      },
      type: {
        string: NONE,
        boolean: NONE,
        integer: NONE,
        json: STANDARD
      }
    }
  }

  def initialize(subscription)
    if subscription
      @type = subscription.type
      @updated_at = subscription.updated_at
    end
  end

  def active?
    types.include?(type) && updated_at.to_datetime > (Time.zone.now - 2.hours).to_datetime
  end

  def can_use_feature?(feature, attribute, value)
    feature_type = FEATURES.dig(*[feature.to_sym, attribute.to_sym, value.to_sym])
    !feature_type || has_required_type?(feature_type)
  end

  def has_required_type?(t)
    t && type_index(t) >= type_index(type)
  end

  def type_index(t)
    self.class.types.index(t)
  end

  def self.types
    [NONE, STANDARD, BUSINESS]
  end
end
