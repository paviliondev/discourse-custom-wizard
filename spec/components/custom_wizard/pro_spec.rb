# frozen_string_literal: true

require_relative '../../plugin_helper'

describe CustomWizard::Pro do
  fab!(:user) { Fabricate(:user) }

  it "initializes pro authentication and subscription" do
    pro = described_class.new
    expect(pro.authentication.class).to eq(CustomWizard::ProAuthentication)
    expect(pro.subscription.class).to eq(CustomWizard::ProSubscription)
  end

  it "returns authorized and subscribed states" do
    pro = described_class.new
    expect(pro.authorized?).to eq(false)
    expect(pro.subscribed?).to eq(false)
  end

  context "subscription" do
    before do
      @pro = described_class.new
    end

    it "updates valid subscriptions" do
      stub_subscription_request(200, valid_subscription)
      expect(@pro.update_subscription).to eq(true)
      expect(@pro.subscribed?).to eq(true)
    end

    it "handles invalid subscriptions" do
      stub_subscription_request(200, invalid_subscription)
      expect(@pro.update_subscription).to eq(false)
      expect(@pro.subscribed?).to eq(false)
    end

    it "handles subscription http errors" do
      stub_subscription_request(404, {})
      expect(@pro.update_subscription).to eq(false)
      expect(@pro.subscribed?).to eq(false)
    end

    it "destroys subscriptions" do
      stub_subscription_request(200, valid_subscription)
      expect(@pro.update_subscription).to eq(true)
      expect(@pro.destroy_subscription).to eq(true)
      expect(@pro.subscribed?).to eq(false)
    end

    it "has class aliases" do
      authenticate_pro
      stub_subscription_request(200, valid_subscription)
      expect(described_class.update_subscription).to eq(true)
      expect(described_class.subscribed?).to eq(true)
    end
  end

  context "authentication" do
    before do
      @pro = described_class.new
      user.update!(admin: true)
    end

    it "generates a valid authentication request url" do
      request_id = SecureRandom.hex(32)
      uri = URI(@pro.authentication_url(user.id, request_id))
      expect(uri.host).to eq(@pro.server)

      parsed_query = Rack::Utils.parse_query uri.query
      expect(parsed_query['public_key'].present?).to eq(true)
      expect(parsed_query['nonce'].present?).to eq(true)
      expect(parsed_query['client_id'].present?).to eq(true)
      expect(parsed_query['auth_redirect'].present?).to eq(true)
      expect(parsed_query['application_name']).to eq(SiteSetting.title)
      expect(parsed_query['scopes']).to eq(@pro.scope)
    end

    def generate_payload(request_id, user_id)
      uri = URI(@pro.authentication_url(user_id, request_id))
      keys = @pro.authentication.get_keys(request_id)
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

      expect(@pro.authentication_response(request_id, payload)).to eq(true)
      expect(@pro.authorized?).to eq(true)
    end

    it "discards authentication response if user who made request as not an admin" do
      user.update!(admin: false)

      request_id = SecureRandom.hex(32)
      payload = generate_payload(request_id, user.id)

      expect(@pro.authentication_response(request_id, payload)).to eq(false)
      expect(@pro.authorized?).to eq(false)
    end

    it "discards authentication response if request_id is invalid" do
      payload = generate_payload(SecureRandom.hex(32), user.id)

      expect(@pro.authentication_response(SecureRandom.hex(32), payload)).to eq(false)
      expect(@pro.authorized?).to eq(false)
    end

    it "destroys authentication" do
      request_id = SecureRandom.hex(32)
      payload = generate_payload(request_id, user.id)
      @pro.authentication_response(request_id, payload)

      expect(@pro.destroy_authentication).to eq(true)
      expect(@pro.authorized?).to eq(false)
    end
  end
end