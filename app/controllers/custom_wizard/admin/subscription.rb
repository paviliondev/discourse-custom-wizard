# frozen_string_literal: true

class CustomWizard::AdminSubscriptionController < CustomWizard::AdminController
  skip_before_action :check_xhr, :preload_json, :verify_authenticity_token, only: [:authorize, :authorize_callback]

  def index
    render_serialized(subscription, CustomWizard::SubscriptionSerializer, root: false)
  end

  def authorize
    request_id = SecureRandom.hex(32)
    cookies[:user_api_request_id] = request_id
    redirect_to subscription.authentication_url(current_user.id, request_id).to_s
  end

  def authorize_callback
    payload = params[:payload]
    request_id = cookies[:user_api_request_id]

    subscription.authentication_response(request_id, payload)
    subscription.update

    redirect_to '/admin/wizards/subscription'
  end

  def destroy_authentication
    if subscription.destroy_authentication
      render json: success_json
    else
      render json: failed_json
    end
  end

  def update_subscription
    if subscription.update
      serialized_subscription = CustomWizard::Subscription::SubscriptionSerializer.new(subscription.subscription, root: false)
      render json: success_json.merge(subscription: serialized_subscription)
    else
      render json: failed_json
    end
  end

  protected

  def subscription
    @subscription ||= CustomWizard::Subscription.new
  end
end
