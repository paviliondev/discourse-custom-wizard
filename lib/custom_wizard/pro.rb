# frozen_string_literal: true

class CustomWizard::Pro
  NAMESPACE ||= "#{CustomWizard::PLUGIN_NAME}_pro"

  attr_reader :authentication,
              :subscription

  def initialize
    @authentication = CustomWizard::ProAuthentication.new
    @subscription = CustomWizard::ProSubscription.new
  end

  def authorized?
    @authentication.active?
  end

  def subscribed?
    @subscription.active?
  end
end