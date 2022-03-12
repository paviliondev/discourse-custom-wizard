# frozen_string_literal: true
class CustomWizard::Subscription::SubscriptionSerializer < ApplicationSerializer
  attributes :type,
             :active,
             :updated_at

  def active
    object.active?
  end
end
