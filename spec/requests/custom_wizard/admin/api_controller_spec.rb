# frozen_string_literal: true

describe CustomWizard::AdminApiController do
  fab!(:admin_user) { Fabricate(:user, admin: true) }
  let(:api_json) { get_wizard_fixture("api/api") }

  before do
    sign_in(admin_user)
  end

  it "does not save if user does not have relevant subscription" do
    put "/admin/wizards/api/:name.json", params: api_json.to_h
    expect(response.status).to eq(400)
  end

  it "saves when user does have relevant subscription" do
    enable_subscription("business")
    put "/admin/wizards/api/:name.json", params: api_json.to_h
    expect(response.status).to eq(200)
  end
end
