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
    validate_after_time
    validate_class(data, :wizard)

    data[:steps].each do |step|
      validate_class(step, :step)

      if step[:fields].present?
        step[:fields].each do |field|
          validate_class(field, :field)
        end
      end
    end

    if data[:actions].present?
      data[:actions].each do |action|
        validate_class(action, :action)
      end
    end

    !errors.any?
  end

  def self.required
    {
      wizard: ['id', 'name', 'steps'],
      step: ['id'],
      field: ['id', 'type'],
      action: ['id', 'type']
    }
  end

  private

  def validate_class(object, klass)
    check_required(object, klass)
    validate_subscription(object, klass)
  end

  def check_required(object, klass)
    self.class.required[klass].each do |attribute|
      if object[attribute].blank?
        errors.add :base, I18n.t("wizard.validation.required", attribute: attribute)
      end
    end
  end

  def validate_subscription(object, klass)
    object.keys.each do |attribute|
      if !@subscription.can_use_feature?(klass, attribute, object[attribute])
        errors.add :base, I18n.t("wizard.validation.subscription", class: klass.to_s, attribute: attribute)
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
