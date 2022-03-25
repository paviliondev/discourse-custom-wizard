class CustomWizard::Subscription
  STANDARD_PRODUCT_ID = 'prod_LNAGVAaIqDsHmB'
  BUSINESS_PRODUCT_ID = 'prod_LNABQ50maBQ1pY'

  def self.attributes
    {
      wizard: {
        required: {
          none: [],
          standard: ['*'],
          business: ['*']
        },
        permitted: {
          none: [],
          standard: ['*'],
          business: ['*']
        }
      },
      step: {
        condition: {
          none: [],
          standard: ['*'],
          business: ['*']
        },
        index: {
          none: [],
          standard: ['*'],
          business: ['*']
        },
        required_data: {
          none: [],
          standard: ['*'],
          business: ['*']
        },
        permitted_params: {
          none: [],
          standard: ['*'],
          business: ['*']
        }
      },
      field: {
        condition: {
          none: [],
          standard: ['*'],
          business: ['*']
        },
        index: {
          none: [],
          standard: ['*'],
          business: ['*']
        },
        type: {
          none: ['label', 'description', 'image', 'required', 'placeholder', 'file'],
          standard: ['*'],
          business: ['*']
        },
        prefill: {
          standard: ['*'],
          business: ['*']
        },
        content: {
          none: [],
          standard: ['*'],
          business: ['*']
        },
        realtime_validations: {
          none: [],
          standard: ['*'],
          business: ['*']
        }
      },
      action: {
        type: {
          none: [],
          standard: ['send_message', 'watch_categories', 'add_to_group'],
          business: ['*']
        }
      },
      custom_field: {
        klass: {
          none: ['topic', 'post'],
          standard: ['topic', 'post'],
          business: ['*']
        },
        type: {
          none: ['string', 'boolean', 'integer'],
          standard: ['string', 'boolean', 'integer'],
          business: ['*']
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
    return true if values === "*"

    ## Subscription type supports some values of the attributes.
    values.include?(value)
  end

  def type
    return :none unless subscribed?
    return :standard if standard?
    return :business if business?
  end

  def subscribed?
    standard? || business?
  end

  def standard?
    @subscription.product_id === STANDARD_PRODUCT_ID
  end

  def business?
    @subscription.product_id === BUSINESS_PRODUCT_ID
  end

  def client_installed?
    defined?(SubscriptionClient) == 'constant' && SubscriptionClient.class == Module
  end

  def find_subscription
    subscription = nil

    if client_installed?
      subscription = SubscriptionClientSubscription.active
        .where(product_id: [STANDARD_PRODUCT_ID, BUSINESS_PRODUCT_ID])
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

  def self.standard?
    new.standard?
  end

  def self.type
    new.type
  end
end
