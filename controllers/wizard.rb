class CustomWizard::WizardController < ::ApplicationController
  prepend_view_path(Rails.root.join('plugins', 'discourse-custom-wizard', 'views'))
  layout 'wizard'

  before_action :ensure_logged_in
  helper_method :wizard_page_title

  def wizard_page_title
    wizard = PluginStore.get('custom_wizard', params[:wizard_id].underscore)
    wizard ? (wizard['name'] || wizard['id']) : I18n.t('wizard.custom_title')
  end

  def index
    respond_to do |format|
      format.json do
        builder = CustomWizard::Builder.new(current_user, params[:wizard_id].underscore)
        if builder.wizard.present?
          wizard = builder.build
          render_serialized(wizard, WizardSerializer)
        else
          render json: { error: I18n.t('wizard.none') }
        end
      end
      format.html {}
    end
  end

  ## clean up if user skips wizard
  def skip
    wizard_id = params[:wizard_id]

    wizard = PluginStore.get('custom_wizard', wizard_id.underscore)

    if wizard['required']
      return render json: { error: I18n.t('wizard.no_skip') }
    end

    user = current_user
    result = success_json
    submission = Array.wrap(PluginStore.get("#{wizard_id}_submissions", user.id)).last

    if submission && submission['redirect_to']
      result.merge!(redirect_to: submission['redirect_to'])
    end

    if submission && !wizard['save_submissions']
      PluginStore.remove("#{wizard['id']}_submissions", user.id)
    end

    if user.custom_fields['redirect_to_wizard'] === wizard_id
      user.custom_fields.delete('redirect_to_wizard')
      user.save_custom_fields(true)
    end

    render json: result
  end
end
