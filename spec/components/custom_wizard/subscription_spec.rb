# frozen_string_literal: true

require_relative '../../plugin_helper'

describe CustomWizard::Subscription do
  fab!(:user) { Fabricate(:user) }

  it "initializes subscription authentication and subscription" do
    subscription = described_class.new
    expect(subscription.authentication.class).to eq(CustomWizard::Subscription::Authentication)
    expect(subscription.subscription.class).to eq(CustomWizard::Subscription::Subscription)
  end

  it "returns authorized and subscribed states" do
    subscription = described_class.new
    expect(subscription.authorized?).to eq(false)
    expect(subscription.subscribed?).to eq(false)
  end

  context "subscription" do
    before do
      @subscription = described_class.new
    end

    it "updates valid subscriptions" do
      stub_subscription_request(200, valid_subscription)
      expect(@subscription.update).to eq(true)
      expect(@subscription.subscribed?).to eq(true)
    end

    it "handles invalid subscriptions" do
      stub_subscription_request(200, invalid_subscription)
      expect(@subscription.update).to eq(false)
      expect(@subscription.subscribed?).to eq(false)
    end

    it "handles subscription http errors" do
      stub_subscription_request(404, {})
      expect(@subscription.update).to eq(false)
      expect(@subscription.subscribed?).to eq(false)
    end

    it "destroys subscriptions" do
      stub_subscription_request(200, valid_subscription)
      expect(@subscription.update).to eq(true)
      expect(@subscription.destroy_subscription).to eq(true)
      expect(@subscription.subscribed?).to eq(false)
    end

    it "has class aliases" do
      authenticate_subscription
      stub_subscription_request(200, valid_subscription)
      expect(described_class.update).to eq(true)
      expect(described_class.subscribed?).to eq(true)
    end
  end

  context "authentication" do
    before do
      @subscription = described_class.new
      user.update!(admin: true)
    end

    it "generates a valid authentication request url" do
      request_id = SecureRandom.hex(32)
      uri = URI(@subscription.authentication_url(user.id, request_id))
      expect(uri.host).to eq(@subscription.server)

      parsed_query = Rack::Utils.parse_query uri.query
      expect(parsed_query['public_key'].present?).to eq(true)
      expect(parsed_query['nonce'].present?).to eq(true)
      expect(parsed_query['client_id'].present?).to eq(true)
      expect(parsed_query['auth_redirect'].present?).to eq(true)
      expect(parsed_query['application_name']).to eq(SiteSetting.title)
      expect(parsed_query['scopes']).to eq(@subscription.scope)
    end

    def generate_payload(request_id, user_id)
      uri = URI(@subscription.authentication_url(user_id, request_id))
      keys = @subscription.authentication.get_keys(request_id)
      raw_payload = {
        key: "12345",
        nonce: keys.nonce,
        push: false,
        api: UserApiKeysController::AUTH_API_VERSION
      }.to_json
      public_key = OpenSSL::PKey::RSA.new(keys.pem)
      Base64.encode64(public_key.public_encrypt(raw_payload))
    end

    it "handles authentication response if request and response is valid" do
      request_id = SecureRandom.hex(32)
      payload = generate_payload(request_id, user.id)

      expect(@subscription.authentication_response(request_id, payload)).to eq(true)
      expect(@subscription.authorized?).to eq(true)
    end

    it "discards authentication response if user who made request as not an admin" do
      user.update!(admin: false)

      request_id = SecureRandom.hex(32)
      payload = generate_payload(request_id, user.id)

      expect(@subscription.authentication_response(request_id, payload)).to eq(false)
      expect(@subscription.authorized?).to eq(false)
    end

    it "discards authentication response if request_id is invalid" do
      payload = generate_payload(SecureRandom.hex(32), user.id)

      expect(@subscription.authentication_response(SecureRandom.hex(32), payload)).to eq(false)
      expect(@subscription.authorized?).to eq(false)
    end

    it "destroys authentication" do
      request_id = SecureRandom.hex(32)
      payload = generate_payload(request_id, user.id)
      @subscription.authentication_response(request_id, payload)

      expect(@subscription.destroy_authentication).to eq(true)
      expect(@subscription.authorized?).to eq(false)
    end
  end
end
