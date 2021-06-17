# frozen_string_literal: true
require_relative '../../plugin_helper'

describe CustomWizard::WizardController do
  fab!(:user) {
    Fabricate(
      :user,
      username: 'angus',
      email: "angus@email.com",
      trust_level: TrustLevel[3]
    )
  }

  let(:permitted_json) {
    JSON.parse(
      File.open(
        "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard/permitted.json"
      ).read
    )
  }

  before do
    CustomWizard::Template.save(
      JSON.parse(File.open(
        "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
      ).read),
    skip_jobs: true)
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

  it 'skips a wizard if user is allowed to skip' do
    put '/w/super-mega-fun-wizard/skip.json'
    expect(response.status).to eq(200)
  end

  it 'lets user skip if user cant access wizard' do
    @template["permitted"] = permitted_json["permitted"]
    CustomWizard::Template.save(@template, skip_jobs: true)

    put '/w/super-mega-fun-wizard/skip.json'
    expect(response.status).to eq(200)
  end

  it 'returns a no skip message if user is not allowed to skip' do
    @template['required'] = 'true'
    CustomWizard::Template.save(@template)
    put '/w/super-mega-fun-wizard/skip.json'
    expect(response.parsed_body['error']).to eq("Wizard can't be skipped")
  end

  it 'skip response contains a redirect_to if in users submissions' do
    @wizard = CustomWizard::Wizard.create(@template["id"], user)
    CustomWizard::Submission.new(@wizard, step_1_field_1: "I am a user submission").save
    put '/w/super-mega-fun-wizard/skip.json'
    expect(response.parsed_body['redirect_to']).to eq('/t/2')
  end
end
