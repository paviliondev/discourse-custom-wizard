require 'rails_helper'

describe CustomWizard::AdminWizardController do
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
    
    template_2 = template.dup
    template_2["id"] = 'super_mega_fun_wizard_2'
    template_2["permitted"] = template_2['permitted']
    CustomWizard::Template.save(template_2, skip_jobs: true)
    
    template_3 = template.dup
    template_3["id"] = 'super_mega_fun_wizard_3'
    template_3["after_signup"] = true
    CustomWizard::Template.save(template_3, skip_jobs: true)
    
    sign_in(admin_user)
  end

  it "returns a basic list of wizard templates and wizard field types" do
    get "/admin/wizards/wizard.json"
    expect(
      response.parsed_body['wizard_list'].map { |w| w['id'] }
    ).to match_array(['super_mega_fun_wizard', 'super_mega_fun_wizard_2', 'super_mega_fun_wizard_3'])
    expect(
      response.parsed_body['field_types'].keys
    ).to eq(CustomWizard::Field.types.keys.map(&:to_s))
  end
  
  it "returns a wizard template" do
    get "/admin/wizards/wizard/#{template['id']}.json"
    expect(response.parsed_body['id']).to eq(template['id'])
    expect(response.parsed_body['steps'].length).to eq(3)
  end
  
  it "removes wizard templates" do
    delete "/admin/wizards/wizard/#{template['id']}.json"
    expect(response.status).to eq(200)
    expect(CustomWizard::Template.exists?(template['id'])).to eq(false)
  end
  
  it "saves wizard templates" do
    template_updated = template.dup
    template_updated['name'] = "Super Mega Fun Wizard 2"
    template_updated['multiple_submissions'] = false
    template_updated['steps'][0]['fields'][0]['label'] = "Text 2"
    
    put "/admin/wizards/wizard/#{template['id']}.json", params: { wizard: template_updated }
    expect(response.status).to eq(200)
    
    updated_template = CustomWizard::Template.find('super_mega_fun_wizard')
    expect(updated_template['name']).to eq("Super Mega Fun Wizard 2")
    expect(updated_template['multiple_submissions']).to eq("false")
    expect(updated_template['steps'][0]['fields'][0]['label']).to eq("Text 2")
  end
end