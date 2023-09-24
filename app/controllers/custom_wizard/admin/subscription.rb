# frozen_string_literal: true
class CustomWizard::SubscriptionController < ::Admin::AdminController
  before_action :ensure_admin

  def index
    subscription = CustomWizard::Subscription.new
    render_json_dump(
      subscribed: subscription.subscribed?,
      subscription_type: subscription.type,
      subscription_attributes: CustomWizard::Subscription.attributes,
    )
  end
end
