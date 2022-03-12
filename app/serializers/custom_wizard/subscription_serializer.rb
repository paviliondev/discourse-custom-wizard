# frozen_string_literal: true
class CustomWizard::SubscriptionSerializer < ApplicationSerializer
  attributes :server
  has_one :authentication, serializer: CustomWizard::Subscription::AuthenticationSerializer, embed: :objects
  has_one :subscription, serializer: CustomWizard::Subscription::SubscriptionSerializer, embed: :objects
end
