# frozen_string_literal: true

require_relative '../../plugin_helper'

describe CustomWizard::Notice do
  fab!(:user) { Fabricate(:user) }
  let(:subscription_message) {
    {
      title: "Title of message about subscription",
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
      stub_request(:get, described_class.subscription_message_url).to_return(status: 200, body: { messages: [subscription_message] }.to_json)
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
      stub_request(:get, described_class.subscription_message_url).to_return(status: 200, body: { messages: [subscription_message] }.to_json)
      described_class.update(skip_plugin: true)

      notice = described_class.list(include_all: true).first
      expect(notice.expired?).to eq(true)
    end

    it "dismisses informational subscription notices" do
      notice = described_class.list(include_all: true).first
      expect(notice.dismissed?).to eq(false)

      notice.dismiss!
      expect(notice.dismissed?).to eq(true)
    end

    it "dismisses all informational subscription notices" do
      4.times do |index|
        subscription_message[:title] += " #{index}"
        stub_request(:get, described_class.subscription_message_url).to_return(status: 200, body: { messages: [subscription_message] }.to_json)
        described_class.update(skip_plugin: true)
      end
      expect(described_class.list.count).to eq(5)
      described_class.dismiss_all
      expect(described_class.list.count).to eq(0)
    end
  end

  context "plugin status" do
    before do
      freeze_time
      stub_request(:get, described_class.plugin_status_url).to_return(status: 200, body: plugin_status.to_json)
      described_class.update(skip_subscription: true)
    end

    it "converts warning into notice" do
      notice = described_class.list.first
      expect(notice.type).to eq(described_class.types[:warning])
      expect(notice.message).to eq(I18n.t("wizard.notice.compatibility_issue.message", domain: described_class.plugin_status_domain))
      expect(notice.created_at.to_datetime).to be_within(1.second).of (plugin_status[:status_changed_at].to_datetime)
    end

    it "expires warning notices if status is recommended or compatible" do
      plugin_status[:status] = 'compatible'
      plugin_status[:status_changed_at] = Time.now
      stub_request(:get, described_class.plugin_status_url).to_return(status: 200, body: plugin_status.to_json)
      described_class.update(skip_subscription: true)

      notice = described_class.list(type: described_class.types[:warning], include_all: true).first
      expect(notice.expired?).to eq(true)
    end

    it "hides plugin status warnings" do
      notice = described_class.list.first
      expect(notice.hidden?).to eq(false)

      notice.hide!
      expect(notice.hidden?).to eq(true)
    end
  end

  it "lists notices not expired more than a day ago" do
    subscription_message[:expired_at] = Time.now - 8.hours
    stub_request(:get, described_class.subscription_message_url).to_return(status: 200, body: { messages: [subscription_message] }.to_json)
    stub_request(:get, described_class.plugin_status_url).to_return(status: 200, body: plugin_status.to_json)

    described_class.update
    expect(described_class.list(include_all: true).length).to eq(2)
  end

  context "connection errors" do
    before do
      freeze_time
    end

    it "creates an error if connection to notice server fails" do
      stub_request(:get, described_class.plugin_status_url).to_return(status: 400, body: plugin_status.to_json)
      described_class.update(skip_subscription: true)

      error = CustomWizard::Notice::ConnectionError.new(:plugin_status)
      expect(error.current_error.present?).to eq(true)
    end

    it "only creates one connection error per type at a time" do
      stub_request(:get, described_class.subscription_message_url).to_return(status: 400, body: { messages: [subscription_message] }.to_json)
      stub_request(:get, described_class.plugin_status_url).to_return(status: 400, body: plugin_status.to_json)

      5.times { described_class.update }

      plugin_status_errors = CustomWizard::Notice::ConnectionError.new(:plugin_status)
      subscription_message_errors = CustomWizard::Notice::ConnectionError.new(:subscription_message)

      expect(plugin_status_errors.current_error[:count]).to eq(5)
      expect(subscription_message_errors.current_error[:count]).to eq(5)
    end

    it "creates a connection error notice if connection errors reach limit" do
      stub_request(:get, described_class.plugin_status_url).to_return(status: 400, body: plugin_status.to_json)

      error = CustomWizard::Notice::ConnectionError.new(:plugin_status)
      error.limit.times { described_class.update(skip_subscription: true) }
      notice = described_class.list(type: described_class.types[:connection_error]).first

      expect(error.current_error[:count]).to eq(error.limit)
      expect(notice.type).to eq(described_class.types[:connection_error])
    end

    it "expires a connection error notice if connection succeeds" do
      stub_request(:get, described_class.plugin_status_url).to_return(status: 400, body: plugin_status.to_json)
      error = CustomWizard::Notice::ConnectionError.new(:plugin_status)
      error.limit.times { described_class.update(skip_subscription: true) }

      stub_request(:get, described_class.plugin_status_url).to_return(status: 200, body: plugin_status.to_json)
      described_class.update(skip_subscription: true)
      notice = described_class.list(type: described_class.types[:connection_error], include_all: true).first

      expect(notice.type).to eq(described_class.types[:connection_error])
      expect(notice.expired_at.present?).to eq(true)
    end
  end
end
