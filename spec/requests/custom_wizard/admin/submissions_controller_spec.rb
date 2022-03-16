# frozen_string_literal: true

describe CustomWizard::AdminSubmissionsController do
  fab!(:admin_user) { Fabricate(:user, admin: true) }
  fab!(:user1) { Fabricate(:user) }
  fab!(:user2) { Fabricate(:user) }
  fab!(:user3) { Fabricate(:user) }

  let(:template) { get_wizard_fixture("wizard") }
  let(:template_2) {
    temp = template.dup
    temp["id"] = "super_mega_fun_wizard_2"
    temp
  }

  before do
    CustomWizard::Template.save(template, skip_jobs: true)
    CustomWizard::Template.save(template_2, skip_jobs: true)

    wizard1 = CustomWizard::Wizard.create(template["id"], user1)
    wizard2 = CustomWizard::Wizard.create(template["id"], user2)
    wizard3 = CustomWizard::Wizard.create(template_2["id"], user3)

    CustomWizard::Submission.new(wizard1, step_1_field_1: "I am a user1's submission").save
    CustomWizard::Submission.new(wizard2, step_1_field_1: "I am a user2's submission").save
    CustomWizard::Submission.new(wizard3, step_1_field_1: "I am a user3's submission").save

    sign_in(admin_user)
  end

  it "returns a list of wizards" do
    get "/admin/wizards/submissions.json"
    expect(response.parsed_body.length).to eq(2)
    expect(response.parsed_body.first['id']).to eq(template['id'])
  end

  it "returns users' submissions for a wizard" do
    get "/admin/wizards/submissions/#{template['id']}.json"
    expect(response.parsed_body['submissions'].length).to eq(2)
  end

  it "downloads submissions" do
    get "/admin/wizards/submissions/#{template_2['id']}/download"
    expect(response.parsed_body.length).to eq(1)
  end
end
