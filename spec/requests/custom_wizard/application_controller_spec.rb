require_relative '../../plugin_helper'

describe ApplicationController do
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
    @template = CustomWizard::Template.find('super_mega_fun_wizard')
  end
  
  context "with signed in user" do
    before do
      sign_in(user)
    end
    
    context "who is required to complete wizard" do
      before do
        user.custom_fields['redirect_to_wizard'] = 'super_mega_fun_wizard'
        user.save_custom_fields(true)
      end
      
      it "redirects if user is required to complete a wizard" do
        get "/"
        expect(response).to redirect_to("/w/super-mega-fun-wizard")
      end
      
      it "saves original destination of user" do
        get '/', headers: { 'REFERER' => "/t/2" }
        expect(
          CustomWizard::Wizard.submissions(@template['id'], user)
            .first['redirect_to']
        ).to eq("/t/2")
      end
    end
    
    context "who is not required to complete wizard" do
      it "does nothing" do
        get "/"
        expect(response.status).to eq(200)
      end
    end
  end
  
  context "with guest" do
    it "does nothing" do
      get "/"
      expect(response.status).to eq(200)
    end
  end
end