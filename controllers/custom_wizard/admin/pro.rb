# frozen_string_literal: true

class CustomWizard::AdminProController < CustomWizard::AdminController
  skip_before_action :check_xhr, :preload_json, :verify_authenticity_token, only: [:authorize, :authorize_callback]

  def index
    render_serialized(CustomWizard::Pro.new, CustomWizard::ProSerializer, root: false)
  end

  def authorize
    request_id = SecureRandom.hex(32)
    cookies[:user_api_request_id] = request_id
    redirect_to CustomWizard::ProAuthentication.generate_request(current_user.id, request_id).to_s
  end

  def authorize_callback
    payload = params[:payload]
    request_id = cookies[:user_api_request_id]

    CustomWizard::ProAuthentication.handle_response(request_id, payload)
    CustomWizard::ProSubscription.update

    redirect_to '/admin/wizards/pro'
  end

  def destroy
    if CustomWizard::ProAuthentication.destroy
      render json: success_json
    else
      render json: failed_json
    end
  end

  def update_subscription
    if CustomWizard::ProSubscription.update
      render json: success_json.merge(
        subscription: CustomWizard::ProSubscriptionSerializer.new(
          CustomWizard::ProSubscription.new,
          root: false
        )
      )
    else
      render json: failed_json
    end
  end
end