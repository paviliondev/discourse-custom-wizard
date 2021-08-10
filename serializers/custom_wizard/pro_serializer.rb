# frozen_string_literal: true
class CustomWizard::ProSerializer < ApplicationSerializer
  attributes :server,
             :authentication,
             :subscription

  def server
    CustomWizard::ProSubscription::SUBSCRIPTION_SERVER
  end

  def authentication
    if object.authentication
      CustomWizard::ProAuthenticationSerializer.new(object.authentication, root: false)
    else
      nil
    end
  end

  def subscription
    if object.subscription
      CustomWizard::ProSubscriptionSerializer.new(object.subscription, root: false)
    else
      nil
    end
  end
end