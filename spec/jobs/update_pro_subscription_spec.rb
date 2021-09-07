# frozen_string_literal: true

require_relative '../plugin_helper'

describe CustomWizard::UpdateProSubscription do
  it "updates the pro subscription" do
    stub_subscription_request(200, valid_subscription)
    described_class.new.execute
    expect(CustomWizard::Pro.subscribed?).to eq(true)
  end
end
