# frozen_string_literal: true

require 'rails_helper'

describe CustomWizard::Builder do
  fab!(:user) { Fabricate(:user) }
  fab!(:trusted_user) { Fabricate(:user, trust_level: 3)}
  
  let!(:template) do
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
    ).read)
  end
  
  let(:permitted_params) {[{"key":"param_key","value":"submission_param_key"}]}
  let(:required_data) {[{"key":"nickname","connector":"equals","value":"name"}]}
  let(:required_data_message) {"Nickname is required to match your name"}
  let(:checkbox_field) {{"id":"checkbox","type":"checkbox","label":"Checkbox"}}
  let(:composer_field) {{"id": "composer","label":"Composer","type":"composer"}}
  let(:dropdown_categories_field) {{"id": "dropdown_categories","type": "dropdown","label": "Dropdown Categories","choices_type": "preset","choices_preset": "categories"}}
  let(:tag_field) {{"id": "tag","type": "tag","label": "Tag","limit": "2"}}
  let(:category_field) {{"id": "category","type": "category","limit": "1","label": "Category"}}
  let(:image_field) {{"id": "image","type": "image","label": "Image"}}
  let(:text_field) {{"id": "text","type": "text","min_length": "12","label": "Text"}}
  let(:textarea_field) {{"id": "textarea","type": "textarea","min_length": "40","label": "Textarea"}}
  let(:text_only_field) {{"id": "text_only","type": "text-only","label": "Text only"}}
  let(:upload_field) {{"id": "upload","type": "upload","file_types": ".jpg,.png,.pdf","label": "Upload"}}
  let(:user_selector_field) {{"id": "user_selector","type": "user-selector","label": "User selector"}}
  let(:dropdown_groups_field) {{"id": "dropdown_groups","type": "dropdown","choices_type": "preset","choices_preset": "groups","label": "Dropdown Groups"}}
  let(:dropdown_tags_field) {{"id": "dropdown_tags","type": "dropdown","choices_type": "preset","choices_preset": "tags","label": "Dropdown Tags"}}
  let(:dropdown_custom_field) {{"id": "dropdown_custom","type": "dropdown","choices_type": "custom","choices": [{"key": "option_1","value": "Option 1"},{"key": "option_2","value": "Option 2"}]}}
  let(:dropdown_translation_field) {{"id": "dropdown_translation","type": "dropdown","choices_type": "translation","choices_key": "key1.key2"}}
  let(:dropdown_categories_filtered_field) {{"id": "dropdown_categories_filtered_field","type": "dropdown","choices_type": "preset","choices_preset": "categories","choices_filters": [{"key": "slug","value": "staff"}]}}
  
  def build_wizard(t = template, u = user, build_opts = {}, params = {})
    CustomWizard::Wizard.add_wizard(t)
    CustomWizard::Builder.new(u, 'welcome').build(build_opts, params)
  end
  
  def add_submission_data(data = {})
    PluginStore.set("welcome_submissions", user.id, {
      name: 'Angus',
      website: 'https://thepavilion.io'
    }.merge(data))
  end
  
  def get_submission_data
    PluginStore.get("welcome_submissions", user.id)
  end
  
  it "returns no steps when disabled" do
    SiteSetting.custom_wizard_enabled = false
    wizard = build_wizard
    expect(wizard.steps.length).to eq(0)
    expect(wizard.name).to eq('Welcome')
  end
  
  context 'enabled' do
    before do
      SiteSetting.custom_wizard_enabled = true
    end
    
    it "returns steps" do
      expect(build_wizard.steps.length).to eq(2)
    end
    
    it 'returns no steps if the multiple submissions are disabled and user has completed it' do
      history_params = {
        action: UserHistory.actions[:custom_wizard_step],
        acting_user_id: user.id,
        context: template['id']
      }
      UserHistory.create!(history_params.merge(subject: template['steps'][0]['id']))
      UserHistory.create!(history_params.merge(subject: template['steps'][1]['id']))      
      
      template["multiple_submissions"] = false
      expect(build_wizard(template).steps.length).to eq(0)
    end
    
    it 'returns no steps if has min trust and user does not meet it' do
      template["min_trust"] = 3
      expect(build_wizard(template).steps.length).to eq(0)
    end
    
    it 'returns steps if it has min trust and user meets it' do
      template["min_trust"] = 3
      expect(build_wizard(template, trusted_user).steps.length).to eq(2)  
    end
    
    it 'returns a wizard with prefilled data if user has partially completed it' do
      add_submission_data
      wizard = build_wizard
      expect(wizard.steps[0].fields.first.value).to eq('Angus')
      expect(wizard.steps[1].fields.first.value).to eq('https://thepavilion.io')
    end
    
    it 'returns a wizard with no prefilled data if options include reset' do
      add_submission_data
      wizard = build_wizard(template, user, reset: true)
      expect(wizard.steps[0].fields.first.value).to eq(nil)
      expect(wizard.steps[1].fields.first.value).to eq(nil)
    end
    
    context 'building steps' do
      it 'returns step metadata' do
        expect(build_wizard.steps[0].title).to eq('Welcome to Pavilion')
        expect(build_wizard.steps[1].title).to eq('Tell us about you')
      end
      
      it 'saves permitted params' do
        template['steps'][0]['permitted_params'] = permitted_params
        wizard = build_wizard(template, user, {}, param_key: 'param_value')
        submissions = get_submission_data
        expect(submissions.first['submission_param_key']).to eq('param_value')
      end
      
      it 'is not permitted if required data is not present' do
        template['steps'][0]['required_data'] = required_data
        expect(build_wizard(template, user).steps[0].permitted).to eq(false)
      end
      
      it "is not permitted if required data is not present" do
        template['steps'][0]['required_data'] = required_data
        add_submission_data(nickname: "John")
        expect(build_wizard(template, user).steps[0].permitted).to eq(false)
      end
      
      it 'it shows required data message if required data has message' do
        template['steps'][0]['required_data'] = required_data
        template['steps'][0]['required_data_message'] = required_data_message
        add_submission_data(nickname: "John")
        wizard = build_wizard(template, user)
        expect(wizard.steps[0].permitted).to eq(false)
        expect(wizard.steps[0].permitted_message).to eq(required_data_message)
      end
      
      it 'is permitted if required data is present' do
        template['steps'][0]['required_data'] = required_data
        PluginStore.set('welcome_submissions', user.id, nickname: "Angus", name: "Angus")
        expect(build_wizard(template, user).steps[0].permitted).to eq(true)
      end
      
      it 'returns field metadata' do
        expect(build_wizard(template, user).steps[0].fields[0].label).to eq("<p>Name</p>")
        expect(build_wizard(template, user).steps[0].fields[0].type).to eq("text")
      end
      
      it 'returns fields' do
        template['steps'][0]['fields'][1] = checkbox_field
        expect(build_wizard(template, user).steps[0].fields.length).to eq(2)
      end
    end
    
    context 'on update' do
      context 'validation' do
        it 'applies min length' do
          template['steps'][0]['fields'][0]['min_length'] = 10
          wizard = build_wizard(template, user)
          updater = wizard.create_updater(template['steps'][0]['id'], name: 'short')
          updater.update
          expect(updater.errors.messages[:name].first).to eq(
            I18n.t('wizard.field.too_short', label: 'Name', min: 10)
          ) 
        end
        
        it 'standardises boolean entries' do
          template['steps'][0]['fields'][0] = checkbox_field
          wizard = build_wizard(template, user)
          updater = wizard.create_updater(template['steps'][0]['id'], checkbox: 'false')
          updater.update
          submissions = get_submission_data
          expect(submissions.first['checkbox']).to eq(false)
        end
        
        it 'requires required fields' do
          wizard = build_wizard
          updater = wizard.create_updater(template['steps'][0]['id'], other_field: 'other')
          updater.update
          expect(updater.errors.messages[:name].first).to eq(
            I18n.t('wizard.field.required', label: 'Name')
          ) 
        end
        
        context 'submisisons' do
          it 'saves submissions' do
          
          end
          
          it "doesn't save submissions if disabled" do
          
          end
        end
      end
      
      context 'custom_step_handlers' do
        it 'runs custom step handlers' do
        
        end
      end
      
      context 'actions' do
        it 'runs all actions attached to a step' do
          
        end
        
        it 'interpolates wizard and user data correctly' do
        
        end
        
        it 'creates a topic' do
        
        end
        
        it 'sends a message' do
        
        end
        
        it 'doesnt sent a message if the required data is not present' do
        
        end
        
        it 'updates a profile' do
        
        end
        
        it 'calls an api' do
        
        end
        
        it 'opens a composer' do
        
        end
        
        it 'adds a user to a group' do
        
        end
        
        it 're-routes a user' do
          
        end
      end
    end
  end
end