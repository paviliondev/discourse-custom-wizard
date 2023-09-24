# frozen_string_literal: true
class CustomWizard::SubscriptionController < ::Admin::AdminController
  before_action :ensure_admin

  def index
    subcription = CustomWizard::Subscription.new
    render_json_dump(
      subscribed: subcription.subscribed?,
      subscription_type: subcription.type,
      subscription_attributes: CustomWizard::Subscription.attributes,
    )
  end
end