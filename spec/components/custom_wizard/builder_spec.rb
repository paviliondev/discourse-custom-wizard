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
  
  def build_wizard(t = template, u = user, build_opts = {}, params = {})
    CustomWizard::Wizard.add_wizard(t)
    CustomWizard::Builder.new(u, 'welcome').build(build_opts, params)
  end
  
  def add_submission_data
    PluginStore.set("welcome_submissions", user.id,
      name: 'Angus',
      website: 'https://thepavilion.io'
    )
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
        template['steps'][0]['permitted_params'] = [
          {
            "key": "param_key",
            "value": "submission_param_key"
          }
        ]
        wizard = build_wizard(template, user, {}, param_key: 'param_value')
        submissions = PluginStore.get("welcome_submissions", user.id)
        expect(submissions.first['submission_param_key']).to eq('param_value')
      end
      
      it 'ensures required data is present' do
      
      end
    end
    
    context 'building fields' do
      it 'returns field data correctly' do
      
      end
      
      it 'returns checkbox fields correctly' do
      
      end
      
      it 'returns upload fields correctly' do
      
      end
      
      it 'returns category fields correctly' do
      
      end
      
      it 'returns tag fields correctly' do
      
      end
      
      it 'returns custom dropdown fields correctly' do
      
      end
      
      it 'returns translated dropdown fields correctly' do
      
      end
      
      it 'returns preset dropdown fields correctly' do
      
      end
      
      it 'applies preset dropdown filters correctly' do
      
      end
      
      it 'prefils profile data correctly' do
      
      end
    end
    
    context 'on update' do
      context 'validation' do
        it 'applies min length correctly' do
        
        end
        
        it 'standardises boolean entries' do
        
        end
        
        it 'requires required fields' do
          ## this may require additional work?
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