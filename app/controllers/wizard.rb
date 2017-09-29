class CustomWizard::WizardController < ::ApplicationController
  def set_layout
    File.expand_path('../../views/layouts/custom_wizard.html.erb', __FILE__)
  end

  def index
    respond_to do |format|
      format.json do
        wizard = CustomWizard::Builder.new(current_user, params[:wizard_id]).build
        render_serialized(wizard, WizardSerializer)
      end
      format.html {}
    end
  end
end
