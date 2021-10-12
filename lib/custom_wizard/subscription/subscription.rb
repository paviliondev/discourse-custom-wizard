# frozen_string_literal: true
class CustomWizard::Subscription::Subscription
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
    %w(core advanced complete)
  end

  def active?
    types.include?(type) && updated_at.to_datetime > (Time.zone.now - 2.hours).to_datetime
  end
end
