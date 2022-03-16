# frozen_string_literal: true
class CustomWizard::Subscription::AuthenticationSerializer < ApplicationSerializer
  attributes :active,
             :client_id,
             :auth_by,
             :auth_at

  def active
    object.active?
  end
end
