# frozen_string_literal: true
class CustomWizard::SubscriptionController < ::Admin::AdminController
  before_action :ensure_admin

  def index
    if params[:update_from_remote]
      subscription = CustomWizard::Subscription.new(true)
    else
      subscription = CustomWizard::Subscription.new
    end

    render_json_dump(
      subscribed: subscription.subscribed?,
      subscription_type: subscription.type,
      subscription_attributes: CustomWizard::Subscription.attributes,
    )
  end
end
