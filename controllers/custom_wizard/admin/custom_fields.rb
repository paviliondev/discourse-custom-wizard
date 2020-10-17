class CustomWizard::CustomFieldsController < CustomWizard::AdminController
  def index
    render_custom_field_list
  end
  
  def update
    field_data = params[:custom_fields]
    
    custom_fields = field_data.map { |data| CustomWizard::CustomFields.new(data) }
    
    custom_fields.each do |field_data|
      custom_field.validate
      
      unless custom_field.valid?
        raise Discourse::InvalidParameters, "Invalid field: '#{custom_field.name}'"
      end
    end
    
    all_fields_saved = true
    
    custom_fields.each do |field|
      unless field.save
        all_fields_saved = false
      end
    end
    
    if all_fields_saved
      render_custom_field_list
    else
      render json: error_json
    end
  end
  
  def render_custom_field_list
    render_serialized(
      CustomWizard::CustomFields.list,
      CustomWizard::CustomFieldsSerializer
    )
  end
end