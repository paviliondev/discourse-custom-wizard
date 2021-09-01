# frozen_string_literal: true

class CustomWizard::AdminProController < CustomWizard::AdminController
  skip_before_action :check_xhr, :preload_json, :verify_authenticity_token, only: [:authorize, :authorize_callback]

  def index
    render_serialized(pro, CustomWizard::ProSerializer, root: false)
  end

  def authorize
    request_id = SecureRandom.hex(32)
    cookies[:user_api_request_id] = request_id
    redirect_to pro.authentication_request(current_user.id, request_id).to_s
  end

  def authorize_callback
    payload = params[:payload]
    request_id = cookies[:user_api_request_id]

    pro.authentication_response(request_id, payload)
    pro.update_subscription

    redirect_to '/admin/wizards/pro'
  end

  def destroy_authentication
    if pro.destroy_authentication
      render json: success_json
    else
      render json: failed_json
    end
  end

  def update_subscription
    if pro.update_subscription
      subscription = CustomWizard::ProSubscriptionSerializer.new(pro.subscription, root: false)
      render json: success_json.merge(subscription: subscription)
    else
      render json: failed_json
    end
  end
  
  protected
  
  def pro
    @pro ||= CustomWizard::Pro.new
  end
end