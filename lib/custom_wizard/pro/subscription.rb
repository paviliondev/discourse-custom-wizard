# frozen_string_literal: true
class CustomWizard::ProSubscription
  include ActiveModel::Serialization

  attr_reader :type,
              :updated_at

  def initialize(subscription)
    if subscription
      @type = subscription.type
      @updated_at = subscription.updated_at
    end
  end

  def types
    %w(community business)
  end

  def active?
    types.include?(type) && updated_at.to_datetime > (Time.zone.now - 2.hours).to_datetime
  end
end
