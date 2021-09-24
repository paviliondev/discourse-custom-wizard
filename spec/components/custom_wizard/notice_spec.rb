# frozen_string_literal: true

require_relative '../../plugin_helper'

describe CustomWizard::Notice do
  fab!(:user) { Fabricate(:user) }
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

  context "subscription message" do
    before do
      freeze_time
      stub_request(:get, described_class.subscription_messages_url).to_return(status: 200, body: { messages: [subscription_message] }.to_json)
      described_class.update(skip_plugin: true)
    end

    it "converts subscription messages into notices" do
      notice = described_class.list.first
      expect(notice.type).to eq(described_class.types[:info])
      expect(notice.message).to eq(subscription_message[:message])
      expect(notice.created_at.to_datetime).to be_within(1.second).of (subscription_message[:created_at].to_datetime)
    end
    
    it "expires notice if subscription message is expired" do
      subscription_message[:expired_at] = Time.now
      stub_request(:get, described_class.subscription_messages_url).to_return(status: 200, body: { messages: [subscription_message] }.to_json)
      described_class.update(skip_plugin: true)

      notice = described_class.list.first
      expect(notice.expired?).to eq(true)
    end
  end

  context "plugin status" do
    before do
      freeze_time
      stub_request(:get, described_class.plugin_status_url).to_return(status: 200, body: { status: plugin_status }.to_json)
      described_class.update(skip_subscription: true)
    end

    it "converts plugin statuses to warn into notices" do
      notice = described_class.list.first
      expect(notice.type).to eq(described_class.types[:warning])
      expect(notice.message).to eq(PrettyText.cook(I18n.t("wizard.notice.compatibility_issue", server: described_class.plugin_status_domain)))
      expect(notice.created_at.to_datetime).to be_within(1.second).of (plugin_status[:status_changed_at].to_datetime)
    end
    
    it "expires unexpired warning notices if status is recommended or compatible" do
      plugin_status[:status] = 'compatible'
      plugin_status[:status_changed_at] = Time.now
      stub_request(:get, described_class.plugin_status_url).to_return(status: 200, body: { status: plugin_status }.to_json)
      described_class.update(skip_subscription: true)

      notice = described_class.list(described_class.types[:warning]).first
      expect(notice.expired?).to eq(true)
    end
  end

  it "lists notices not expired more than a day ago" do
    subscription_message[:expired_at] = Time.now - 8.hours
    stub_request(:get, described_class.subscription_messages_url).to_return(status: 200, body: { messages: [subscription_message] }.to_json)
    stub_request(:get, described_class.plugin_status_url).to_return(status: 200, body: { status: plugin_status }.to_json)

    described_class.update
    expect(described_class.list.length).to eq(2)
  end
end