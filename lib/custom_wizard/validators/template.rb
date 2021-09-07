# frozen_string_literal: true
class CustomWizard::TemplateValidator
  include HasErrors
  include ActiveModel::Model

  def initialize(data, opts = {})
    @data = data
    @opts = opts
    @pro = CustomWizard::Pro.new
  end

  def perform
    data = @data

    check_id(data, :wizard)
    check_required(data, :wizard)
    validate_after_time
    validate_pro(data, :wizard)

    data[:steps].each do |step|
      check_required(step, :step)
      validate_pro(step, :step)

      if step[:fields].present?
        step[:fields].each do |field|
          validate_pro(field, :field)
          check_required(field, :field)
        end
      end
    end

    if data[:actions].present?
      data[:actions].each do |action|
        validate_pro(action, :action)
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

  def self.pro
    {
      wizard: {},
      step: {
        condition: 'present',
        index: 'conditional'
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

  def validate_pro(object, type)
    self.class.pro[type].each do |property, pro_type|
      is_pro = object[property.to_s].present? && (
        pro_type === 'present' ||
        (pro_type === 'conditional' && object[property.to_s].is_a?(Hash)) ||
        (pro_type.is_a?(Array) && pro_type.include?(object[property.to_s]))
      )

      if is_pro && !@pro.subscribed?
        errors.add :base, I18n.t("wizard.validation.pro", type: type.to_s, property: property)
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
end
