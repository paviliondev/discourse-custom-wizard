require 'rails_helper'

describe CustomWizard::AdminSubmissionsController do
  fab!(:admin_user) {Fabricate(:user, admin: true)}
  fab!(:user1) {Fabricate(:user)}
  fab!(:user2) {Fabricate(:user)}
  
  let(:template) {
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
    ).read)
  }
  
  before do
    CustomWizard::Template.save(template, skip_jobs: true)
    CustomWizard::Wizard.set_submissions(template['id'], user1,
      step_1_field_1: "I am a user1's submission"
    )
    CustomWizard::Wizard.set_submissions(template['id'], user2,
      step_1_field_1: "I am a user2's submission"
    )
    sign_in(admin_user)
  end

  it "returns a basic list of wizards" do
    get "/admin/wizards/submissions.json"
    expect(response.parsed_body.length).to eq(1)
    expect(response.parsed_body.first['id']).to eq(template['id'])
  end
  
  it "returns the all user's submissions for a wizard" do
    get "/admin/wizards/submissions/#{template['id']}.json"
    expect(response.parsed_body['submissions'].length).to eq(2)
  end
  
  it "returns the all user's submissions for a wizard" do
    get "/admin/wizards/submissions/#{template['id']}.json"
    expect(response.parsed_body['submissions'].length).to eq(2)
  end
  
  it "downloads all user submissions" do
    get "/admin/wizards/submissions/#{template['id']}/download"
    expect(response.parsed_body.length).to eq(2)
  end
end