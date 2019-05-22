class CustomWizard::AuthorizationController < ::ApplicationController
  skip_before_action :check_xhr,
                     :preload_json,
                     :redirect_to_login_if_required,
                     :verify_authenticity_token

  def callback
   # TODO: work out which service it relates to!
   CustomWizard::Authorization.set_code(service, params[:code])
   CustomWizard::Authorization.get_access_token(service)
  end
end
