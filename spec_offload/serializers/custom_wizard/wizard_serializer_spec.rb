# frozen_string_literal: true

require 'rails_helper'

describe CustomWizard::WizardSerializer do
  fab!(:user) { Fabricate(:user) }
  fab!(:category) { Fabricate(:category) }

  before do
    template = JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
    ).read)
    CustomWizard::Wizard.add_wizard(template)
    @wizard = CustomWizard::Wizard.create('super_mega_fun_wizard', user)
  end
  
  it 'should return the wizard attributes' do
    built_wizard = CustomWizard::Builder.new(@wizard.id, user).build
    json = CustomWizard::WizardSerializer.new(built_wizard, scope: Guardian.new(user)).as_json
    expect(json[:custom_wizard][:id]).to eq("super_mega_fun_wizard")
    expect(json[:custom_wizard][:name]).to eq("Super Mega Fun Wizard")
    expect(json[:custom_wizard][:background]).to eq("#333333")
    expect(json[:custom_wizard][:required]).to eq(false)
  end
  
  it "should return the wizard user attributes" do
    built_wizard = CustomWizard::Builder.new(@wizard.id, user).build
    json = CustomWizard::WizardSerializer.new(built_wizard, scope: Guardian.new(user)).as_json
    expect(json[:custom_wizard][:user]).to eq(BasicUserSerializer.new(user, root: false).as_json)
  end
  
  it "should not return category attributes if there are no category fields" do
    built_wizard = CustomWizard::Builder.new(@wizard.id, user).build
    json = CustomWizard::WizardSerializer.new(built_wizard, scope: Guardian.new(user)).as_json
    expect(json[:custom_wizard][:categories].present?).to eq(false)
    expect(json[:custom_wizard][:uncategorized_category_id].present?).to eq(false)
  end 
  
  it "should return category attributes if there is a category selector field" do
    built_wizard = CustomWizard::Builder.new(@wizard.id, user).build
    json = CustomWizard::WizardSerializer.new(built_wizard, scope: Guardian.new(user)).as_json
    expect(json[:custom_wizard][:categories].present?).to eq(true)
    expect(json[:custom_wizard][:uncategorized_category_id].present?).to eq(true)
  end
end