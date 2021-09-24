# frozen_string_literal: true

require_relative '../../plugin_helper'

describe CustomWizard::SubscriptionSerializer do
  it 'should return subscription attributes' do
    subscription = CustomWizard::Subscription.new
    serialized = described_class.new(subscription, root: false)

    expect(serialized.server).to eq(subscription.server)
    expect(serialized.authentication.class).to eq(CustomWizard::Subscription::Authentication)
    expect(serialized.subscription.class).to eq(CustomWizard::Subscription::Subscription)
  end
end
