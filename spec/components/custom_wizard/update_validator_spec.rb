require 'rails_helper'

describe CustomWizard::UpdateValidator do
  fab!(:user) { Fabricate(:user) }
  
  let(:template) {
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
    ).read).with_indifferent_access
  }
  
  before do
    CustomWizard::Template.save(
      JSON.parse(File.open(
        "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
      ).read),
    skip_jobs: true)
    @template = CustomWizard::Template.find('super_mega_fun_wizard')
  end
  
  def perform_validation(step_id, submission)
    wizard = CustomWizard::Builder.new(@template[:id], user).build
    updater = wizard.create_updater(step_id, submission)
    updater.validate
    updater
  end
  
  it 'applies min length to text type fields' do
    min_length = 3
    
    @template[:steps][0][:fields][0][:min_length] = min_length
    @template[:steps][0][:fields][1][:min_length] = min_length
    @template[:steps][0][:fields][2][:min_length] = min_length
    
    CustomWizard::Template.save(@template)
    
    updater = perform_validation('step_1', step_1_field_1: 'Te')
    expect(
      updater.errors.messages[:step_1_field_1].first
    ).to eq(I18n.t('wizard.field.too_short', label: 'Text', min: min_length))
    
    updater = perform_validation('step_1', step_1_field_2: 'Te')    
    expect(
      updater.errors.messages[:step_1_field_2].first
    ).to eq(I18n.t('wizard.field.too_short', label: 'Textarea', min: min_length))
    
    updater = perform_validation('step_1', step_1_field_3: 'Te')    
    expect(
      updater.errors.messages[:step_1_field_3].first
    ).to eq(I18n.t('wizard.field.too_short', label: 'Composer', min: min_length))
  end
  
  it 'standardises boolean entries' do
    updater = perform_validation('step_2', step_2_field_5: 'false')
    expect(updater.submission['step_2_field_5']).to eq(false)
  end
  
  it 'requires required fields' do
    @template[:steps][0][:fields][1][:required] = true
    CustomWizard::Template.save(@template)
    
    updater = perform_validation('step_1', step_1_field_2: nil)    
    expect(
      updater.errors.messages[:step_1_field_2].first
    ).to eq(I18n.t('wizard.field.required', label: 'Textarea')) 
  end
end