# frozen_string_literal: true
class CustomWizard::UserController < ::Admin::AdminController
  before_action :ensure_admin
  requires_plugin "discourse-custom-wizard"

  def clear_redirect
    user = User.find_by(id: params[:id])

    if user
      user.custom_fields["redirect_to_wizard"] = nil
      user.save_custom_fields(true)
      render json: success_json
    else
      render json: failed_json
    end
  end
end
