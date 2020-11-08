class CustomWizard::AdminCustomFieldsController < CustomWizard::AdminController
  def index
    render_json_dump(custom_field_list)
  end
  
  def update
    fields_to_save = []
    
    custom_field_params[:custom_fields].each do |field_param|
      field_id = nil
      field_data = {}
      
      if saved_field = CustomWizard::CustomField.find(field_param[:name])
        CustomWizard::CustomField::ATTRS.each do |attr|
          field_data[attr] = field_param[attr] || saved_field.send(attr)
        end
        field_id = saved_field.id
      end
            
      fields_to_save.push(CustomWizard::CustomField.new(field_id, field_data))
    end
    
    PluginStoreRow.transaction do
      fields_to_save.each do |field| 
        unless field.save
          raise ActiveRecord::Rollback.new,
            field.errors.any? ?
              field.errors.full_messages.join("\n\n") :
              I18n.t("wizard.custom_field.error.save_default", name: field.name)
        end
      end
    end

    render json: success_json
  end
  
  private
  
  def custom_field_params
    params.permit(
      custom_fields: [
        :name,
        :klass,
        :type,
        serializers: []
      ]
    )
  end
end