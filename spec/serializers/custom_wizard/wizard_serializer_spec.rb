# frozen_string_literal: true

require 'rails_helper'

describe CustomWizardSerializer do
  fab!(:user) { Fabricate(:user) }
  fab!(:category) { Fabricate(:category) }

  let!(:template) do
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
    ).read)
  end
  
  let(:category_field) {{"id": "category","type": "category","limit": "1","label": "Category"}}
  
  def build_wizard(t = template, u = user, build_opts = {}, params = {})
    CustomWizard::Wizard.add_wizard(t)
    CustomWizard::Builder.new('welcome', u).build(build_opts, params)
  end

  it 'should return the wizard attributes' do
    json = CustomWizardSerializer.new(build_wizard, scope: Guardian.new(user)).as_json
    expect(json[:custom_wizard][:id]).to eq("welcome")
    expect(json[:custom_wizard][:name]).to eq("Welcome")
    expect(json[:custom_wizard][:background]).to eq("#006da3")
    expect(json[:custom_wizard][:required]).to eq(false)
    expect(json[:custom_wizard][:min_trust]).to eq(1)
  end
  
  it "should return the wizard user attributes" do
    json = CustomWizardSerializer.new(build_wizard, scope: Guardian.new(user)).as_json
    expect(json[:custom_wizard][:permitted]).to eq(true)
    expect(json[:custom_wizard][:user]).to eq(BasicUserSerializer.new(user, root: false).as_json)
  end
  
  it "should not return category attributes if there are no category fields" do
    json = CustomWizardSerializer.new(build_wizard, scope: Guardian.new(user)).as_json
    expect(json[:custom_wizard][:categories].present?).to eq(false)
    expect(json[:custom_wizard][:uncategorized_category_id].present?).to eq(false)
  end 
  
  it "should return category attributes if there is a category selector field" do
    template['steps'][0]['fields'][0] = category_field
    json = CustomWizardSerializer.new(build_wizard(template), scope: Guardian.new(user)).as_json
    expect(json[:custom_wizard][:categories].present?).to eq(true)
    expect(json[:custom_wizard][:uncategorized_category_id].present?).to eq(true)
  end
end