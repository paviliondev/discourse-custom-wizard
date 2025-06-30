# frozen_string_literal: true

class CustomWizard::Subscription
  PRODUCT_HIERARCHY = %w[community standard business]

  def self.attributes
    {
      wizard: {
        required: {
          none: [],
          standard: ["*"],
          business: ["*"],
          community: ["*"],
        },
        permitted: {
          none: [],
          standard: ["*"],
          business: ["*"],
          community: ["*", "!#{CustomWizard::Wizard::GUEST_GROUP_ID}"],
        },
        restart_on_revisit: {
          none: [],
          standard: ["*"],
          business: ["*"],
          community: ["*"],
        },
        after_time_groups: {
          none: [],
          standard: [],
          business: ["*"],
          community: [],
        },
      },
      step: {
        condition: {
          none: [],
          standard: ["*"],
          business: ["*"],
          community: ["*"],
        },
        required_data: {
          none: [],
          standard: ["*"],
          business: ["*"],
          community: ["*"],
        },
        permitted_params: {
          none: [],
          standard: ["*"],
          business: ["*"],
          community: ["*"],
        },
      },
      field: {
        condition: {
          none: [],
          standard: ["*"],
          business: ["*"],
          community: ["*"],
        },
        type: {
          none: %w[text textarea text_only date time date_time number checkbox dropdown upload],
          standard: ["*"],
          business: ["*"],
          community: ["*"],
        },
        realtime_validations: {
          none: [],
          standard: ["*"],
          business: ["*"],
          community: ["*"],
        },
      },
      action: {
        type: {
          none: %w[create_topic update_profile open_composer route_to],
          standard: %w[
            create_topic
            update_profile
            open_composer
            route_to
            send_message
            watch_categories
            watch_tags
            add_to_group
          ],
          business: ["*"],
          community: ["*"],
        },
      },
      custom_field: {
        klass: {
          none: %w[topic post],
          standard: %w[topic post],
          business: ["*"],
          community: ["*"],
        },
        type: {
          none: %w[string boolean integer],
          standard: %w[string boolean integer],
          business: ["*"],
          community: ["*"],
        },
      },
      api: {
        all: {
          none: [],
          standard: [],
          business: ["*"],
          community: ["*"],
        },
      },
    }
  end

  attr_accessor :product_id, :product_slug

  def initialize(update = false)
  end

  def includes?(feature, attribute, value = nil)
    return true
  end

  def type
    return :none unless subscribed?
    return :business if business?
    return :standard if standard?
    :community if community?
  end

  def subscribed?
    return true
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
    return true
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
    value
      .reduce([]) do |result, v|
        ## We can only validate mapped assignment values at the moment
        result << v["output"] if v.is_a?(Hash) && v["type"] === "assignment"
        result
      end
      .flatten
  end
end
