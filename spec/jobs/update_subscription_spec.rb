# frozen_string_literal: true

require_relative '../plugin_helper'

describe Jobs::CustomWizardUpdateSubscription do
  it "updates the subscription" do
    stub_subscription_request(200, valid_subscription)
    described_class.new.execute
    expect(CustomWizard::Subscription.subscribed?).to eq(true)
  end
end
