module ApplicationControllerCWExtension
  extend ActiveSupport::Concern
  
  included do
    before_action :redirect_to_wizard_if_required, if: :current_user
  end

  def redirect_to_wizard_if_required
    wizard_id = current_user.custom_fields['redirect_to_wizard']
    @excluded_routes ||= SiteSetting.wizard_redirect_exclude_paths.split('|') + ['/w/']
    url = request.referer || request.original_url

    if request.format === 'text/html' && !@excluded_routes.any? {|str| /#{str}/ =~ url} && wizard_id
      if request.referer !~ /\/w\// && request.referer !~ /\/invites\//
        CustomWizard::Wizard.set_submission_redirect(current_user, wizard_id, request.referer)
      end

      if CustomWizard::Wizard.exists?(wizard_id)
        redirect_to "/w/#{wizard_id.dasherize}"
      end
    end
  end
end

class ApplicationController
  prepend ApplicationControllerCWExtension if SiteSetting.custom_wizard_enabled
end