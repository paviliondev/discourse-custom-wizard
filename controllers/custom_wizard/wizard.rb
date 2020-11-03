class CustomWizard::WizardController < ::ApplicationController
  prepend_view_path(Rails.root.join('plugins', 'discourse-custom-wizard', 'views'))
  layout 'wizard'
  
  before_action :ensure_plugin_enabled
  helper_method :wizard_page_title
  helper_method :theme_ids

  def wizard
    CustomWizard::Wizard.create(params[:wizard_id].underscore, current_user)
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
        builder = CustomWizard::Builder.new(params[:wizard_id].underscore, current_user)
        
        if builder.wizard.present?
          builder_opts = {}
          builder_opts[:reset] = params[:reset]
          built_wizard = builder.build(builder_opts, params)
          
          render_serialized(built_wizard, ::CustomWizard::WizardSerializer, root: false)
        else
          render json: { error: I18n.t('wizard.none') }
        end
      end
      format.html {}
    end
  end

  def skip
    params.require(:wizard_id)
    
    if wizard.required && !wizard.completed? && wizard.permitted?
      return render json: { error: I18n.t('wizard.no_skip') }
    end

    result = success_json
    user = current_user
    
    if user
      submission = wizard.current_submission
      if submission && submission['redirect_to']
        result.merge!(redirect_to: submission['redirect_to'])
      end

      if user.custom_fields['redirect_to_wizard'] === wizard.id
        user.custom_fields.delete('redirect_to_wizard')
        user.save_custom_fields(true)
      end
    end

    render json: result
  end
  
  private
  
  def ensure_plugin_enabled
    unless SiteSetting.custom_wizard_enabled
      redirect_to path("/")
    end
  end
end
