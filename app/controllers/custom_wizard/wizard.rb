# frozen_string_literal: true
class CustomWizard::WizardController < ::ApplicationController
  before_action :ensure_plugin_enabled
  before_action :ensure_logged_in, only: [:skip]

  def show
    if wizard.present?
      render json: CustomWizard::WizardSerializer.new(wizard, scope: guardian, root: false).as_json, status: 200
    else
      render json: { error: I18n.t('wizard.none') }
    end
  end

  def skip
    params.require(:wizard_id)

    if wizard.required && !wizard.completed? && wizard.permitted?
      return render json: { error: I18n.t('wizard.no_skip') }
    end

    result = { success: 'OK' }

    if current_user && wizard.can_access?
      if redirect_to = wizard.current_submission&.redirect_to
        result.merge!(redirect_to: redirect_to)
      end

      wizard.cleanup_on_skip!
    end

    render json: result
  end

  protected

  def wizard
    @wizard ||= begin
      builder = CustomWizard::Builder.new(params[:wizard_id].underscore, current_user)
      return nil unless builder.present?
      opts = {}
      opts[:reset] = params[:reset]
      builder.build(opts, params)
    end
  end

  private

  def ensure_plugin_enabled
    unless SiteSetting.custom_wizard_enabled
      redirect_to path("/")
    end
  end
end
