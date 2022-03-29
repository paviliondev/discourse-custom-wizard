# frozen_string_literal: true
class CustomWizard::WizardController < ::ActionController::Base
  helper ApplicationHelper

  include CurrentUser
  include CanonicalURL::ControllerExtensions
  include GlobalPath

  prepend_view_path(Rails.root.join('plugins', 'discourse-custom-wizard', 'app', 'views'))
  layout :set_wizard_layout

  before_action :preload_wizard_json
  before_action :ensure_plugin_enabled
  before_action :ensure_logged_in, only: [:skip]

  helper_method :wizard_page_title
  helper_method :wizard_theme_id
  helper_method :wizard_theme_lookup
  helper_method :wizard_theme_translations_lookup

  def set_wizard_layout
    action_name === 'qunit' ? 'qunit' : 'wizard'
  end

  def index
    respond_to do |format|
      format.json do
        if wizard.present?
          render json: CustomWizard::WizardSerializer.new(wizard, scope: guardian, root: false).as_json, status: 200
        else
          render json: { error: I18n.t('wizard.none') }
        end
      end
      format.html do
        render "default/empty"
      end
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

  def qunit
    raise Discourse::InvalidAccess.new if Rails.env.production?

    respond_to do |format|
      format.html do
        render "default/empty"
      end
    end
  end

  protected

  def ensure_logged_in
    raise Discourse::NotLoggedIn.new unless current_user.present?
  end

  def guardian
    @guardian ||= Guardian.new(current_user, request)
  end

  def wizard
    @wizard ||= begin
      builder = CustomWizard::Builder.new(params[:wizard_id].underscore, current_user)
      return nil unless builder.present?
      opts = {}
      opts[:reset] = params[:reset]
      builder.build(opts, params)
    end
  end

  def wizard_page_title
    wizard ? (wizard.name || wizard.id) : I18n.t('wizard.custom_title')
  end

  def wizard_theme_id
    wizard ? wizard.theme_id : nil
  end

  def wizard_theme_lookup(name)
    Theme.lookup_field(wizard_theme_id, view_context.mobile_view? ? :mobile : :desktop, name)
  end

  def wizard_theme_translations_lookup
    Theme.lookup_field(wizard_theme_id, :translations, I18n.locale)
  end

  def preload_wizard_json
    return if request.xhr? || request.format.json?
    return if request.method != "GET"

    store_preloaded("siteSettings", SiteSetting.client_settings_json)
  end

  def store_preloaded(key, json)
    @preloaded ||= {}
    @preloaded[key] = json.gsub("</", "<\\/")
  end

  private

  def ensure_plugin_enabled
    unless SiteSetting.custom_wizard_enabled
      redirect_to path("/")
    end
  end
end
