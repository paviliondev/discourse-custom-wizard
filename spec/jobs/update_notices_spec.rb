# frozen_string_literal: true

require_relative '../plugin_helper'

describe Jobs::CustomWizardUpdateNotices do
  let(:subscription_message) {
    {
      message: "Message about subscription",
      type: "info",
      created_at: Time.now - 3.day,
      expired_at: nil
    }
  }
  let(:plugin_status) {
    {
      name: 'discourse-custom-wizard',
      status: 'incompatible',
      status_changed_at: Time.now - 3.day
    }
  }

  it "updates the notices" do
    stub_request(:get, CustomWizard::Notice.subscription_message_url).to_return(status: 200, body: { messages: [subscription_message] }.to_json)
    stub_request(:get, CustomWizard::Notice.plugin_status_url).to_return(status: 200, body: plugin_status.to_json)

    described_class.new.execute
    expect(CustomWizard::Notice.list.length).to eq(2)
  end
end
