require 'rails_helper'

describe CustomWizard::AdminLogsController do
  fab!(:admin_user) { Fabricate(:user, admin: true) }
  
  before do
    CustomWizard::Log.create("First log message")
    CustomWizard::Log.create("Second log message")
    CustomWizard::Log.create("Third log message")
    sign_in(admin_user)
  end

  it "returns a list of logs" do
    get "/admin/wizards/logs.json"
    expect(response.parsed_body.length).to eq(3)
  end
  
  it "paginates" do
    get "/admin/wizards/logs.json", params: { page: 1, limit: 2 }
    expect(response.parsed_body.length).to eq(1)
  end
end