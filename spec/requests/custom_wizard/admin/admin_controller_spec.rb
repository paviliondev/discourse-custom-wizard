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
      it "returns the right subscription details" do
        get "/admin/wizards.json"
        expect(response.parsed_body["subscribed"]).to eq(false)
        expect(response.parsed_body["subscription_attributes"]).to eq(CustomWizard::Subscription.attributes.as_json)
        expect(response.parsed_body["subscription_client_installed"]).to eq(false)
      end
    end

    context "with a subscription" do
      before do
        enable_subscription("standard")
        load File.expand_path("#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/subscription_client.rb", __FILE__)
      end

      it "returns the right subscription details" do
        get "/admin/wizards.json"
        expect(response.parsed_body["subscribed"]).to eq(true)
        expect(response.parsed_body["subscription_type"]).to eq("standard")
        expect(response.parsed_body["subscription_client_installed"]).to eq(true)
      end
    end
  end
end