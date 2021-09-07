# frozen_string_literal: true
require_relative '../../../plugin_helper'

describe CustomWizard::AdminProController do
  fab!(:admin_user) { Fabricate(:user, admin: true) }

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

  before do
    @pro = CustomWizard::Pro.new
    sign_in(admin_user)
  end

  it "#index" do
    get "/admin/wizards/pro.json"
    expect(response.parsed_body['server']).to eq(@pro.server)
    expect(response.parsed_body['authentication'].deep_symbolize_keys).to eq(CustomWizard::ProAuthenticationSerializer.new(@pro.authentication, root: false).as_json)
    expect(response.parsed_body['subscription'].deep_symbolize_keys).to eq(CustomWizard::ProSubscriptionSerializer.new(@pro.subscription, root: false).as_json)
  end

  it "#authorize" do
    get "/admin/wizards/pro/authorize"
    expect(response.status).to eq(302)
    expect(cookies[:user_api_request_id].present?).to eq(true)
  end

  it "#destroy_authentication" do
    request_id = SecureRandom.hex(32)
    payload = generate_payload(request_id, admin_user.id)
    @pro.authentication_response(request_id, payload)

    delete "/admin/wizards/pro/authorize.json"

    expect(response.status).to eq(200)
    expect(CustomWizard::Pro.authorized?).to eq(false)
  end

  context "subscription" do
    before do
      stub_subscription_request(200, valid_subscription)
    end

    it "handles authentication response and the updates subscription" do
      request_id = cookies[:user_api_request_id] = SecureRandom.hex(32)
      payload = generate_payload(request_id, admin_user.id)
      get "/admin/wizards/pro/authorize/callback", params: { payload: payload }

      expect(response).to redirect_to("/admin/wizards/pro")
      expect(CustomWizard::Pro.subscribed?).to eq(true)
    end

    it "updates the subscription" do
      authenticate_pro
      post "/admin/wizards/pro/subscription.json"

      expect(response.status).to eq(200)
      expect(CustomWizard::Pro.subscribed?).to eq(true)
    end
  end
end
