module CustomWizardCustomFieldPreloader
  def preload_custom_fields(objects, fields)
    if objects.present?
      @cw_klass = objects.first.class.name.underscore
      if cw_fields.any?
        cw_fields.each do |field|
          fields << field.name
        end
      end
    end
    super(objects, fields)
  end
  
  def cw_fields
    CustomWizard::CustomField.list_by(:klass, @cw_klass)
  end
end