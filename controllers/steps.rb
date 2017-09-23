class CustomWizard::StepsController < ::ApplicationController
  def all
    respond_to do |format|
      format.json do
        wizard = CustomWizard::Builder.new(current_user, params[:wizard_id]).build
        render_serialized(wizard, WizardSerializer)
      end
      format.html {}
    end
  end
end
