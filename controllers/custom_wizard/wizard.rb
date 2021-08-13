# frozen_string_literal: true
class CustomWizard::WizardController < ::ApplicationController
  include ApplicationHelper
  prepend_view_path(Rails.root.join('plugins', 'discourse-custom-wizard', 'views'))
  layout 'wizard'

  before_action :ensure_plugin_enabled
  helper_method :wizard_page_title
  helper_method :wizard_theme_id
  helper_method :wizard_theme_lookup
  helper_method :wizard_theme_translations_lookup

  def wizard
    @builder = CustomWizard::Builder.new(params[:wizard_id].underscore, current_user)
    @wizard ||= @builder.build
    @wizard
  end

  def wizard_page_title
    wizard ? (wizard.name || wizard.id) : I18n.t('wizard.custom_title')
  end

  def wizard_theme_id
    wizard ? wizard.theme_id : nil
  end

  def wizard_theme_lookup(name)
    Theme.lookup_field(wizard_theme_id, mobile_view? ? :mobile : :desktop, name)
  end

  def wizard_theme_translations_lookup
    Theme.lookup_field(wizard_theme_id, :translations, I18n.locale)
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

    if user && wizard.can_access?
      submission = wizard.current_submission

      if submission.present? && submission.redirect_to
        result.merge!(redirect_to: submission.redirect_to)
      end

      submission.remove if submission.present?
      wizard.reset
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
