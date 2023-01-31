# frozen_string_literal: true

describe CustomWizard::WizardController do
  fab!(:user) { Fabricate(:user, username: 'angus', email: "angus@email.com", trust_level: TrustLevel[3]) }
  let(:wizard_template) { get_wizard_fixture("wizard") }
  let(:permitted_json) { get_wizard_fixture("wizard/permitted") }

  before do
    CustomWizard::Template.save(wizard_template, skip_jobs: true)
    @template = CustomWizard::Template.find("super_mega_fun_wizard")
    sign_in(user)
  end

  context 'plugin disabled' do
    before do
      SiteSetting.custom_wizard_enabled = false
    end

    it 'redirects to root' do
      get '/w/super-mega-fun-wizard', xhr: true
      expect(response).to redirect_to("/")
    end
  end

  it 'returns wizard' do
    get '/w/super-mega-fun-wizard.json'
    expect(response.parsed_body["id"]).to eq("super_mega_fun_wizard")
  end

  it 'returns missing message if no wizard exists' do
    get '/w/super-mega-fun-wizards.json'
    expect(response.parsed_body["error"]).to eq("We couldn't find a wizard at that address.")
  end

  context 'when user skips the wizard' do

    it 'skips a wizard if user is allowed to skip' do
      put '/w/super-mega-fun-wizard/skip.json'
      expect(response.status).to eq(200)
    end

    it 'lets user skip if user cant access wizard' do
      enable_subscription("standard")
      @template["permitted"] = permitted_json["permitted"]
      CustomWizard::Template.save(@template, skip_jobs: true)
      put '/w/super-mega-fun-wizard/skip.json'
      expect(response.status).to eq(200)
    end

    it 'returns a no skip message if user is not allowed to skip' do
      enable_subscription("standard")
      @template['required'] = 'true'
      CustomWizard::Template.save(@template)
      put '/w/super-mega-fun-wizard/skip.json'
      expect(response.parsed_body['error']).to eq("Wizard can't be skipped")
    end

    it 'skip response contains a redirect_to if in users submissions' do
      @wizard = CustomWizard::Wizard.create(@template["id"], user)
      CustomWizard::Submission.new(@wizard, redirect_to: "/t/2").save
      put '/w/super-mega-fun-wizard/skip.json'
      expect(response.parsed_body['redirect_to']).to eq('/t/2')
    end

    it 'deletes the users redirect_to_wizard if present' do
      user.custom_fields['redirect_to_wizard'] = @template["id"]
      user.save_custom_fields(true)
      @wizard = CustomWizard::Wizard.create(@template["id"], user)
      put '/w/super-mega-fun-wizard/skip.json'
      expect(response.status).to eq(200)
      expect(user.reload.redirect_to_wizard).to eq(nil)
    end

    it "deletes the submission if user has filled up some data" do
      @wizard = CustomWizard::Wizard.create(@template["id"], user)
      CustomWizard::Submission.new(@wizard, step_1_field_1: "Hello World").save
      current_submission = @wizard.current_submission
      put '/w/super-mega-fun-wizard/skip.json'
      submissions = CustomWizard::Submission.list(@wizard).submissions

      expect(submissions.any? { |submission| submission.id == current_submission.id }).to eq(false)
    end

    it "starts from the first step if user visits after skipping the wizard" do
      put '/w/super-mega-fun-wizard/steps/step_1.json', params: {
        fields: {
          step_1_field_1: "Text input"
        }
      }
      put '/w/super-mega-fun-wizard/skip.json'
      get '/w/super-mega-fun-wizard.json'

      expect(response.parsed_body["start"]).to eq('step_1')
    end
  end
end
