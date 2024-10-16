# frozen_string_literal: true
module CustomWizardCustomFieldPreloader
  def preload_custom_fields(objects, fields)
    if objects.present? && cw_fields_enabled?
      @cw_klass = objects.first.class.name.underscore
      cw_fields.each { |field| fields << field[:name] } if cw_fields.any?
    end
    super(objects, fields)
  end

  def cw_fields_enabled?
    SiteSetting.custom_wizard_enabled && CustomWizard::CustomField.enabled?
  end

  def cw_fields
    CustomWizard::CustomField.list_by(:klass, @cw_klass)
  end
end
