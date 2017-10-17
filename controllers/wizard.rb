class CustomWizard::WizardController < ::ApplicationController
  prepend_view_path(Rails.root.join('plugins', 'discourse-custom-wizard', 'views'))
  layout 'wizard'
  helper_method :wizard_page_title

  def wizard_page_title
    wizard = PluginStore.get('custom_wizard', params[:wizard_id].underscore)
    wizard['name'] || wizard['id']
  end

  def index
    respond_to do |format|
      format.json do
        wizard = CustomWizard::Builder.new(current_user, params[:wizard_id].underscore).build
        render_serialized(wizard, WizardSerializer)
      end
      format.html {}
    end
  end
end
