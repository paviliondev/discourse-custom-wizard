# frozen_string_literal: true
class CustomWizard::ProSerializer < ApplicationSerializer
  attributes :server
  has_one :authentication, serializer: CustomWizard::ProAuthenticationSerializer, embed: :objects
  has_one :subscription, serializer: CustomWizard::ProSubscriptionSerializer, embed: :objects
end
