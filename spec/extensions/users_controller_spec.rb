require 'rails_helper'

describe CustomWizardUsersController, type: :request do
  let(:template) do
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
    ).read)
  end
  
  before do
    @controller = UsersController.new
  end
  
  it "redirects a user to wizard after sign up if after signup is enabled" do
    template['after_signup'] = true
    CustomWizard::Template.save(template, skip_jobs: true)
    sign_in(Fabricate(:user))
    get "/u/account-created"
    expect(response).to redirect_to("/w/super-mega-fun-wizard")
  end    
end