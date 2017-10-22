class CustomWizard::WizardController < ::ApplicationController
  prepend_view_path(Rails.root.join('plugins', 'discourse-custom-wizard', 'views'))
  layout 'wizard'
  helper_method :wizard_page_title

  def wizard_page_title
    wizard = PluginStore.get('custom_wizard', params[:wizard_id].underscore)
    wizard ? (wizard['name'] || wizard['id']) : I18n.t('wizard.custom_title')
  end

  def index
    respond_to do |format|
      format.json do
        template = CustomWizard::Builder.new(current_user, params[:wizard_id].underscore)
        if template.wizard.present?
          wizard = template.build
          render_serialized(wizard, WizardSerializer)
        else
          render json: { error: I18n.t('wizard.none') }
        end
      end
      format.html {}
    end
  end
end
