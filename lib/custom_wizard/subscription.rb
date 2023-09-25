# frozen_string_literal: true
require "discourse_subscription_client"

class CustomWizard::Subscription
  PRODUCT_HIERARCHY = %w[
    community
    standard
    business
  ]

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
          community: ['*', "!#{CustomWizard::Wizard::GUEST_GROUP_ID}"]
        },
        restart_on_revisit: {
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
          standard: ['create_topic', 'update_profile', 'open_composer', 'route_to', 'send_message', 'watch_categories', 'watch_tags', 'add_to_group'],
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
      },
      api: {
        all: {
          none: [],
          standard: [],
          business: ['*'],
          community: ['*']
        }
      }
    }
  end

  attr_accessor :product_id,
                :product_slug

  def initialize
    result = ::DiscourseSubscriptionClient.find_subscriptions("discourse-custom-wizard")

    if result&.any?
      ids_and_slugs = result.subscriptions.map do |subscription|
        {
          id: subscription.product_id,
          slug: result.products[subscription.product_id]
        }
      end

      id_and_slug = ids_and_slugs.sort do |a, b|
        PRODUCT_HIERARCHY.index(b[:slug]) - PRODUCT_HIERARCHY.index(a[:slug])
      end.first

      @product_id = id_and_slug[:id]
      @product_slug = id_and_slug[:slug]
    end

    @product_slug ||= ENV["CUSTOM_WIZARD_PRODUCT_SLUG"]
  end

  def includes?(feature, attribute, value = nil)
    attributes = self.class.attributes[feature]

    ## Attribute is not part of a subscription
    return true unless attributes.present? && attributes.key?(attribute)

    values = attributes[attribute][type]

    ## Subscription type does not support the attribute.
    return false if values.blank?

    ## Value is an exception for the subscription type
    if (exceptions = get_exceptions(values)).any?
      value = mapped_output(value) if CustomWizard::Mapper.mapped_value?(value)
      value = [*value].map(&:to_s)
      return false if (exceptions & value).length > 0
    end

    ## Subscription type supports all values of the attribute.
    return true if values.include?("*")

    ## Subscription type supports some values of the attributes.
    values.include?(value)
  end

  def type
    return :none unless subscribed?
    return :business if business?
    return :standard if standard?
    :community if community?
  end

  def subscribed?
    standard? || business? || community?
  end

  def standard?
    product_slug === "standard"
  end

  def business?
    product_slug === "business"
  end

  def community?
    product_slug === "community"
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

  def self.includes?(feature, attribute, value)
    new.includes?(feature, attribute, value)
  end

  protected

  def get_exceptions(values)
    values.reduce([]) do |result, value|
      result << value.split("!").last if value.start_with?("!")
      result
    end
  end

  def mapped_output(value)
    value.reduce([]) do |result, v|
      ## We can only validate mapped assignment values at the moment
      result << v["output"] if v.is_a?(Hash) && v["type"] === "assignment"
      result
    end.flatten
  end
end
