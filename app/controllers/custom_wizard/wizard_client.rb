# frozen_string_literal: true
class CustomWizard::WizardClientController < ::ApplicationController
  before_action :ensure_plugin_enabled
  before_action :set_builder

  private

  def ensure_plugin_enabled
    redirect_to path("/") unless SiteSetting.custom_wizard_enabled
  end

  def guest_id
    return nil if current_user.present?
    cookies[:custom_wizard_guest_id] ||= CustomWizard::Wizard.generate_guest_id
    cookies[:custom_wizard_guest_id]
  end

  def set_builder
    @builder = CustomWizard::Builder.new(params[:wizard_id].underscore, current_user, guest_id)
  end
end
