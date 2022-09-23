# frozen_string_literal: true
class CustomWizard::Subscription
  STANDARD_PRODUCT_ID = 'prod_MH11woVoZU5AWb'
  BUSINESS_PRODUCT_ID = 'prod_MH0wT627okh3Ef'
  COMMUNITY_PRODUCT_ID = 'prod_MU7l9EjxhaukZ7'

  def self.attributes
    {
      wizard: {
        required: {
          none: [],
          standard: ['*'],
          business: ['*'],
          community: ['*']
        },
        permitted: {
          none: [],
          standard: ['*'],
          business: ['*'],
          community: ['*']
        }
      },
      step: {
        condition: {
          none: [],
          standard: ['*'],
          business: ['*'],
          community: ['*']
        },
        index: {
          none: [],
          standard: ['*'],
          business: ['*'],
          community: ['*']
        },
        required_data: {
          none: [],
          standard: ['*'],
          business: ['*'],
          community: ['*']
        },
        permitted_params: {
          none: [],
          standard: ['*'],
          business: ['*'],
          community: ['*']
        }
      },
      field: {
        condition: {
          none: [],
          standard: ['*'],
          business: ['*'],
          community: ['*']
        },
        index: {
          none: [],
          standard: ['*'],
          business: ['*'],
          community: ['*']
        },
        type: {
          none: ['text', 'textarea', 'text_only', 'date', 'time', 'date_time', 'number', 'checkbox', 'dropdown', 'upload'],
          standard: ['*'],
          business: ['*'],
          community: ['*']
        },
        realtime_validations: {
          none: [],
          standard: ['*'],
          business: ['*'],
          community: ['*']
        }
      },
      action: {
        type: {
          none: ['create_topic', 'update_profile', 'open_composer', 'route_to'],
          standard: ['create_topic', 'update_profile', 'open_composer', 'route_to', 'send_message', 'watch_categories', 'add_to_group'],
          business: ['*'],
          community: ['*']
        }
      },
      custom_field: {
        klass: {
          none: ['topic', 'post'],
          standard: ['topic', 'post'],
          business: ['*'],
          community: ['*']
        },
        type: {
          none: ['string', 'boolean', 'integer'],
          standard: ['string', 'boolean', 'integer'],
          business: ['*'],
          community: ['*']
        }
      }
    }
  end

  def initialize
    @subscription = find_subscription
  end

  def includes?(feature, attribute, value)
    attributes = self.class.attributes[feature]

    ## Attribute is not part of a subscription
    return true unless attributes.present? && attributes.key?(attribute)

    values = attributes[attribute][type]

    ## Subscription type does not support the attribute.
    return false if values.blank?

    ## Subscription type supports all values of the attribute.
    return true if values.first === "*"

    ## Subscription type supports some values of the attributes.
    values.include?(value)
  end

  def type
    return :none unless subscribed?
    return :standard if standard?
    return :business if business?
    return :community if community?
  end

  def subscribed?
    standard? || business? || community?
  end

  def standard?
    @subscription.product_id === STANDARD_PRODUCT_ID
  end

  def business?
    @subscription.product_id === BUSINESS_PRODUCT_ID
  end

  def community?
    @subscription.product_id === COMMUNITY_PRODUCT_ID
  end

  def client_installed?
    defined?(SubscriptionClient) == 'constant' && SubscriptionClient.class == Module
  end

  def find_subscription
    subscription = nil

    if client_installed?
      subscription = SubscriptionClientSubscription.active
        .where(product_id: [STANDARD_PRODUCT_ID, BUSINESS_PRODUCT_ID, COMMUNITY_PRODUCT_ID])
        .order("product_id = '#{BUSINESS_PRODUCT_ID}' DESC")
        .first
    end

    unless subscription
      subscription = OpenStruct.new(product_id: nil)
    end

    subscription
  end

  def self.subscribed?
    new.subscribed?
  end

  def self.business?
    new.business?
  end

  def self.community?
    new.community?
  end

  def self.standard?
    new.standard?
  end

  def self.type
    new.type
  end

  def self.client_installed?
    new.client_installed?
  end

  def self.includes?(feature, attribute, value)
    new.includes?(feature, attribute, value)
  end
end
