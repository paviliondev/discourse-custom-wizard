class CustomWizard::AdminController < ::Admin::AdminController
  before_action :ensure_admin
  
  def index
  end
  
  private
  
  def find_wizard
    params.require(:wizard_id)
    @wizard = CustomWizard::Wizard.create(params[:wizard_id].underscore)
  end
  
  def custom_field_list
    serialize_data(CustomWizard::CustomField.list, CustomWizard::CustomFieldSerializer)
  end
end