class CustomWizard::WizardController < ::ApplicationController
  prepend_view_path(Rails.root.join('plugins', 'discourse-custom-wizard', 'views'))
  layout 'wizard'

  helper_method :wizard_page_title
  helper_method :theme_ids

  def wizard
    CustomWizard::Template.new(PluginStore.get('custom_wizard', params[:wizard_id].underscore))
  end

  def wizard_page_title
    wizard ? (wizard.name || wizard.id) : I18n.t('wizard.custom_title')
  end

  def theme_ids
    wizard ? [wizard.theme_id] : nil
  end

  def index
    respond_to do |format|
      format.json do
        builder = CustomWizard::Builder.new(current_user, params[:wizard_id].underscore)
        builder_opts = {}
        builder_opts[:reset] = params[:reset] if params[:reset]

        if builder.wizard.present?
          wizard = builder.build(builder_opts, params)
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
    params.require(:wizard_id)

    wizard_id = params[:wizard_id]

    user = current_user
    wizard_template = PluginStore.get('custom_wizard', wizard_id.underscore)
    wizard = CustomWizard::Wizard.new(user, wizard_template)

    if wizard.required && !wizard.completed? && wizard.permitted?
      return render json: { error: I18n.t('wizard.no_skip') }
    end

    result = success_json

    if user
      submission = Array.wrap(PluginStore.get("#{wizard_id}_submissions", user.id)).last

      if submission && submission['redirect_to']
        result.merge!(redirect_to: submission['redirect_to'])
      end

      if submission && !wizard.save_submissions
        PluginStore.remove("#{wizard_id}_submissions", user.id)
      end

      if user.custom_fields['redirect_to_wizard'] === wizard_id
        user.custom_fields.delete('redirect_to_wizard')
        user.save_custom_fields(true)
      end
    end

    render json: result
  end
end
