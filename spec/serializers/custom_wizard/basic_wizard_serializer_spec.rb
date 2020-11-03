# frozen_string_literal: true

require 'rails_helper'

describe CustomWizard::BasicWizardSerializer do
  fab!(:user) { Fabricate(:user) }
  
  it 'should return basic wizard attributes' do
    CustomWizard::Template.save(
      JSON.parse(File.open(
        "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
      ).read),
    skip_jobs: true)
    json = CustomWizard::BasicWizardSerializer.new(
      CustomWizard::Builder.new("super_mega_fun_wizard", user).build,
      scope: Guardian.new(user)
    ).as_json
    expect(json[:basic_wizard][:id]).to eq("super_mega_fun_wizard")
    expect(json[:basic_wizard][:name]).to eq("Super Mega Fun Wizard")
  end
end