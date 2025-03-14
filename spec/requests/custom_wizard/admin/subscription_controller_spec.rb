# frozen_string_literal: true

describe CustomWizard::SubscriptionController do
  fab!(:admin_user) { Fabricate(:user, admin: true) }

  it "requires an admin" do
    get "/admin/wizards.json"
    expect(response.status).to eq(404)
  end

  context "with an admin" do
    before { sign_in(admin_user) }

    context "without a subscription" do
      before { disable_subscriptions }

      it "returns the right subscription details" do
        get "/admin/wizards/subscription.json"
        expect(response.parsed_body["subscribed"]).to eq(false)
        expect(response.parsed_body["subscription_attributes"]).to eq(
          CustomWizard::Subscription.attributes.as_json,
        )
      end
    end

    context "with a subscription" do
      before { enable_subscription("standard") }

      it "returns the right subscription details" do
        get "/admin/wizards/subscription.json"
        expect(response.parsed_body["subscribed"]).to eq(true)
        expect(response.parsed_body["subscription_type"]).to eq("standard")
      end
    end
  end
end
