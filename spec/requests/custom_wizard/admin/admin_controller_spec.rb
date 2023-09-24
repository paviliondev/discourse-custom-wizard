# frozen_string_literal: true

describe CustomWizard::AdminController do
  fab!(:admin_user) { Fabricate(:user, admin: true) }

  it "requires an admin" do
    get "/admin/wizards.json"
    expect(response.status).to eq(404)
  end

  context "with an admin" do
    before do
      sign_in(admin_user)
    end

    context "without a subscription" do
      before do
        disable_subscriptions
        define_client_classes
      end

      it "returns the right subscription details" do
        get "/admin/wizards/subscription.json"
        expect(response.parsed_body["subscribed"]).to eq(false)
        expect(response.parsed_body["subscription_attributes"]).to eq(CustomWizard::Subscription.attributes.as_json)
      end
    end

    context "with a subscription" do
      before do
        enable_subscription("standard")
        define_client_classes
      end

      it "returns the right subscription details" do
        get "/admin/wizards/subscription.json"
        expect(response.parsed_body["subscribed"]).to eq(true)
        expect(response.parsed_body["subscription_type"]).to eq("standard")
      end
    end
  end
end
