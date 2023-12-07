# frozen_string_literal: true

describe CustomWizard::AdminLogsController do
  fab!(:admin_user) { Fabricate(:user, admin: true) }
  let(:template) { get_wizard_fixture("wizard") }

  before do
    ["first", "second", "third"].each_with_index do |key, index|
      temp = template.dup
      temp["id"] = "#{key}_test_wizard"
      CustomWizard::Template.save(temp, skip_jobs: true)
      CustomWizard::Log.create("#{key}_test_wizard", "perform_#{key}_action", "#{key}_test_user", "#{key} log message")
    end
    sign_in(admin_user)
  end

  it "returns a list of wizards" do
    get "/admin/wizards/logs.json"
    expect(response.parsed_body.length).to eq(3)
  end

  it "returns a list of logs for a wizard" do
    get "/admin/wizards/logs/first_test_wizard.json"
    expect(response.parsed_body['logs'].length).to eq(1)
  end

  it "paginates" do
    get "/admin/wizards/logs/first_test_wizard.json", params: { page: 1 }
    expect(response.parsed_body['logs'].length).to eq(0)
  end

  it "returns total logs for a wizard" do
    get "/admin/wizards/logs/first_test_wizard.json"
    expect(response.parsed_body['total']).to eq(1)
  end

  it "returns basic wizard" do
    get "/admin/wizards/logs/first_test_wizard.json"
    expect(response.parsed_body['wizard']['id']).to eq("first_test_wizard")
  end
end
