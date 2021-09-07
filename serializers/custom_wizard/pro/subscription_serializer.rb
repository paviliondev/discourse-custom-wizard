# frozen_string_literal: true
class CustomWizard::ProSubscriptionSerializer < ApplicationSerializer
  attributes :type,
             :active,
             :updated_at

  def active
    object.active?
  end
end
