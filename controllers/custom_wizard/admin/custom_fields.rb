class CustomWizard::AdminCustomFieldsController < CustomWizard::AdminController
  def index
    render_json_dump(custom_field_list)
  end
  
  def update        
    custom_fields = custom_field_params[:custom_fields].map do |data|
      CustomWizard::CustomField.new(data.to_h)
    end
    
    custom_fields.each do |custom_field|
      custom_field.validate
      
      unless custom_field.valid?
        raise Discourse::InvalidParameters,
          custom_field.errors.full_messages.join("\n\n")
      end
    end
    
    all_fields_saved = true
    
    custom_fields.each do |field|
      unless field.save
        all_fields_saved = false
      end
    end
    
    if all_fields_saved
      CustomWizard::CustomField.register_fields
      render json: success_json
    else
      render json: error_json
    end
  end
  
  private
  
  def custom_field_params
    params.permit(
      custom_fields: [
        :klass,
        :name,
        :type,
        serializers: []
      ]
    )
  end
end