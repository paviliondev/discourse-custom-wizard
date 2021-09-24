# frozen_string_literal: true
class CustomWizard::TemplateValidator
  include HasErrors
  include ActiveModel::Model

  def initialize(data, opts = {})
    @data = data
    @opts = opts
    @subscription = CustomWizard::Subscription.new
  end

  def perform
    data = @data

    check_id(data, :wizard)
    check_required(data, :wizard)
    validate_after_time
    validate_subscription(data, :wizard)

    data[:steps].each do |step|
      check_required(step, :step)
      validate_subscription(step, :step)

      if step[:fields].present?
        step[:fields].each do |field|
          validate_subscription(field, :field)
          check_required(field, :field)
        end
      end
    end

    if data[:actions].present?
      data[:actions].each do |action|
        validate_subscription(action, :action)
        check_required(action, :action)
      end
    end

    if errors.any?
      false
    else
      true
    end
  end

  def self.required
    {
      wizard: ['id', 'name', 'steps'],
      step: ['id'],
      field: ['id', 'type'],
      action: ['id', 'type']
    }
  end

  def self.subscription
    {
      wizard: {
        save_submissions: 'false',
        restart_on_revisit: 'true',
      },
      step: {
        condition: 'present',
        index: 'conditional',
        required_data: 'present',
        permitted_params: 'present'
      },
      field: {
        condition: 'present',
        index: 'conditional'
      },
      action: {
        type: %w[
          send_message
          add_to_group
          create_category
          create_group
          send_to_api
        ]
      }
    }
  end

  private

  def check_required(object, type)
    self.class.required[type].each do |property|
      if object[property].blank?
        errors.add :base, I18n.t("wizard.validation.required", property: property)
      end
    end
  end

  def validate_subscription(object, type)
    self.class.subscription[type].each do |property, subscription_type|
      val = object[property.to_s]
      is_subscription = (val != nil) && (
        subscription_type === 'present' && val.present? ||
        (['true', 'false'].include?(subscription_type) && cast_bool(val) == cast_bool(subscription_type)) ||
        (subscription_type === 'conditional' && val.is_a?(Hash)) ||
        (subscription_type.is_a?(Array) && subscription_type.include?(val))
      )

      if is_subscription && !@subscription.subscribed?
        errors.add :base, I18n.t("wizard.validation.subscription", type: type.to_s, property: property)
      end
    end
  end

  def check_id(object, type)
    if type === :wizard && @opts[:create] && CustomWizard::Template.exists?(object[:id])
      errors.add :base, I18n.t("wizard.validation.conflict", wizard_id: object[:id])
    end
  end

  def validate_after_time
    return unless @data[:after_time]

    wizard = CustomWizard::Wizard.create(@data[:id]) if !@opts[:create]
    current_time = wizard.present? ? wizard.after_time_scheduled : nil
    new_time = @data[:after_time_scheduled]

    begin
      active_time = Time.parse(new_time.present? ? new_time : current_time).utc
    rescue ArgumentError
      invalid_time = true
    end

    if invalid_time || active_time.blank? || active_time < Time.now.utc
      errors.add :base, I18n.t("wizard.validation.after_time")
    end
  end

  def cast_bool(val)
    ActiveRecord::Type::Boolean.new.cast(val)
  end
end
