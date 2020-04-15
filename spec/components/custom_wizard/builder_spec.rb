# frozen_string_literal: true

require 'rails_helper'

describe CustomWizard::Builder do
  fab!(:user) { Fabricate(:user, username: 'angus') }
  fab!(:trusted_user) { Fabricate(:user, trust_level: 3) }
  fab!(:category1) { Fabricate(:category, name: 'cat1') }
  fab!(:category2) { Fabricate(:category, name: 'cat2') }
  fab!(:group) { Fabricate(:group) }
  
  let!(:template) do
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
    ).read)
  end
  
  def build_wizard(t = template, u = user, build_opts = {}, params = {})
    CustomWizard::Wizard.add_wizard(t)
    CustomWizard::Builder.new('welcome', u).build(build_opts, params)
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
  
  def run_update(t = template, step_id = nil, data = {})
    wizard = build_wizard(t)
    updater = wizard.create_updater(step_id || t['steps'][0]['id'], data)
    updater.update
    updater
  end
  
  context 'disabled' do
    before do
      SiteSetting.custom_wizard_enabled = false
    end
    
    it "returns no steps" do
      wizard = build_wizard
      expect(wizard.steps.length).to eq(0)
      expect(wizard.name).to eq('Welcome')
    end
    
    it "doesn't save submissions" do
      run_update(template, nil, name: 'Angus')
      expect(get_submission_data.blank?).to eq(true)
    end
  end
  
  context 'enabled' do
    before do
      SiteSetting.custom_wizard_enabled = true
    end
    
    it "returns steps" do
      expect(build_wizard.steps.length).to eq(2)
    end
    
    it 'returns no steps if multiple submissions are disabled and user has completed' do
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
    
    it 'returns no steps if user is not permitted' do
      template["min_trust"] = 3
      expect(build_wizard(template).steps.length).to eq(0)
    end
    
    it 'returns steps if user is permitted' do
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
      it 'saves submissions' do
        run_update(template, nil, name: 'Angus')
        expect(get_submission_data.first['name']).to eq('Angus')
      end
      
      context 'validation' do
        it 'applies min length' do
          template['steps'][0]['fields'][0]['min_length'] = 10
          updater = run_update(template, nil, name: 'short')
          expect(updater.errors.messages[:name].first).to eq(
            I18n.t('wizard.field.too_short', label: 'Name', min: 10)
          ) 
        end
        
        it 'standardises boolean entries' do
          template['steps'][0]['fields'][0] = checkbox_field
          run_update(template, nil, checkbox: 'false')
          expect(get_submission_data.first['checkbox']).to eq(false)
        end
        
        it 'requires required fields' do
          template['steps'][0]['fields'][0]['required'] = true
          expect(run_update(template).errors.messages[:name].first).to eq(
            I18n.t('wizard.field.required', label: 'Name')
          ) 
        end
      end
      
      it 'runs actions attached to a step' do
        run_update(template, template['steps'][1]['id'], name: "Gus")
        expect(user.name).to eq('Gus')
      end
    end
  end
end