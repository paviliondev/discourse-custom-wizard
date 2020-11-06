require 'rails_helper'

describe CustomWizard::StepsController do
  fab!(:user) {
    Fabricate(
      :user,
      username: 'angus',
      email: "angus@email.com",
      trust_level: TrustLevel[3]
    ) 
  }

  before do
    CustomWizard::Template.save(
      JSON.parse(File.open(
        "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
      ).read),
    skip_jobs: true)
    sign_in(user)
  end
    
  it 'performs a step update' do
    put '/w/super-mega-fun-wizard/steps/step_1.json', params: {
      fields: {
        step_1_field_1: "Text input"
      }
    }
    expect(response.status).to eq(200)
    
    wizard = CustomWizard::Builder.new("super_mega_fun_wizard", user).build
    expect(wizard.current_submission['step_1_field_1']).to eq("Text input")
    expect(wizard.start.id).to eq("step_2")
  end
  
  it "works if the step has no fields" do
    put '/w/super-mega-fun-wizard/steps/step_1.json'
    expect(response.status).to eq(200)
    
    wizard = CustomWizard::Builder.new("super_mega_fun_wizard", user).build
    expect(wizard.start.id).to eq("step_2")
  end
end