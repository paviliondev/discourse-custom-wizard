# frozen_string_literal: true
class CustomWizard::AdminController < ::Admin::AdminController
  before_action :ensure_admin

  private

  def find_wizard
    params.require(:wizard_id)
    @wizard = CustomWizard::Wizard.create(params[:wizard_id].underscore)
    raise Discourse::InvalidParameters.new(:wizard_id) unless @wizard
  end

  def custom_field_list
    serialize_data(CustomWizard::CustomField.full_list, CustomWizard::CustomFieldSerializer)
  end

  def render_error(message)
    render json: failed_json.merge(error: message)
  end
end
