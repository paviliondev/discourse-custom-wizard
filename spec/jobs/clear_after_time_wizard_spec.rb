# frozen_string_literal: true

require_relative '../plugin_helper'

describe Jobs::ClearAfterTimeWizard do
  fab!(:user1) { Fabricate(:user) }
  fab!(:user2) { Fabricate(:user) }
  fab!(:user3) { Fabricate(:user) }
  
  let(:template) {
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
    ).read).with_indifferent_access
  }

  it "clears wizard redirect for all users " do
    after_time_template = template.dup
    after_time_template["after_time"] = true
    after_time_template["after_time_scheduled"] = (Time.now + 3.hours).iso8601
    
    CustomWizard::Template.save(after_time_template)
    
    Jobs::SetAfterTimeWizard.new.execute(wizard_id: 'super_mega_fun_wizard')
        
    expect(
      UserCustomField.where(
        name: 'redirect_to_wizard',
        value: 'super_mega_fun_wizard'
      ).length
    ).to eq(3)
    
    described_class.new.execute(wizard_id: 'super_mega_fun_wizard')
    
    expect(
      UserCustomField.where("
        name = 'redirect_to_wizard' AND
        value = 'super_mega_fun_wizard'
      ").exists?
    ).to eq(false)
  end
end