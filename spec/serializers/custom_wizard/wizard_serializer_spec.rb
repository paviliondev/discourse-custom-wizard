# frozen_string_literal: true

require_relative '../../plugin_helper'

describe CustomWizard::WizardSerializer do
  fab!(:user) { Fabricate(:user) }
  fab!(:category) { Fabricate(:category) }

  before do
    CustomWizard::Template.save(
      JSON.parse(File.open(
        "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
      ).read),
    skip_jobs: true)
    @template = CustomWizard::Template.find('super_mega_fun_wizard')
  end
  
  it 'should return the wizard attributes' do
    json = CustomWizard::WizardSerializer.new(
      CustomWizard::Builder.new(@template[:id], user).build,
      scope: Guardian.new(user)
    ).as_json
    expect(json[:wizard][:id]).to eq("super_mega_fun_wizard")
    expect(json[:wizard][:name]).to eq("Super Mega Fun Wizard")
    expect(json[:wizard][:background]).to eq("#333333")
    expect(json[:wizard][:required]).to eq(false)
  end
  
  it 'should return the wizard steps' do
    json = CustomWizard::WizardSerializer.new(
      CustomWizard::Builder.new(@template[:id], user).build,
      scope: Guardian.new(user)
    ).as_json
    expect(json[:wizard][:steps].length).to eq(3)
  end
  
  it "should return the wizard user attributes" do
    json = CustomWizard::WizardSerializer.new(
      CustomWizard::Builder.new(@template[:id], user).build,
      scope: Guardian.new(user)
    ).as_json
    expect(
      json[:wizard][:user]
    ).to eq(BasicUserSerializer.new(user, root: false).as_json)
  end
  
  it "should not return categories if there are no category fields" do
    @template[:steps][2][:fields].delete_at(2)
    CustomWizard::Template.save(@template)
    
    json = CustomWizard::WizardSerializer.new(
      CustomWizard::Builder.new(@template[:id], user).build,
      scope: Guardian.new(user)
    ).as_json
    expect(json[:wizard][:categories].present?).to eq(false)
    expect(json[:wizard][:uncategorized_category_id].present?).to eq(false)
  end 
  
  it "should return categories if there is a category selector field" do
    json = CustomWizard::WizardSerializer.new(
      CustomWizard::Builder.new(@template[:id], user).build,
      scope: Guardian.new(user)
    ).as_json
    expect(json[:wizard][:categories].present?).to eq(true)
    expect(json[:wizard][:uncategorized_category_id].present?).to eq(true)
  end
  
  it 'should return groups if there is a group selector field' do
    json = CustomWizard::WizardSerializer.new(
      CustomWizard::Builder.new(@template[:id], user).build,
      scope: Guardian.new(user)
    ).as_json
    expect(json[:wizard][:groups].length).to eq(8)
  end
  
  it 'should not return groups if there is not a group selector field' do
    @template[:steps][2][:fields].delete_at(3)
    CustomWizard::Template.save(@template)
    
    json = CustomWizard::WizardSerializer.new(
      CustomWizard::Builder.new(@template[:id], user).build,
      scope: Guardian.new(user)
    ).as_json
    expect(json[:wizard][:groups].present?).to eq(false)
  end
end