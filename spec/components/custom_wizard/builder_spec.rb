# frozen_string_literal: true

require 'rails_helper'

describe CustomWizard::Builder do
  fab!(:user) { Fabricate(:user, username: 'angus', email: "angus@email.com", trust_level: TrustLevel[2]) }
  fab!(:new_user) { Fabricate(:user, trust_level: 0) }
  fab!(:category1) { Fabricate(:category, name: 'cat1') }
  fab!(:category2) { Fabricate(:category, name: 'cat2') }
  fab!(:group) { Fabricate(:group) }
  
  before do
    Group.refresh_automatic_group!(:trust_level_2)
    template = JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
    ).read)
    CustomWizard::Wizard.add_wizard(template)
    @wizard = CustomWizard::Wizard.create('super_mega_fun_wizard', user)
  end
  
  context 'disabled' do
    before do
      SiteSetting.custom_wizard_enabled = false
    end
    
    it "returns nil" do
      expect(CustomWizard::Builder.new(@wizard.id, user).build).to eq(nil)
    end
  end
  
  context 'enabled' do
    before do
      SiteSetting.custom_wizard_enabled = true
    end
    
    it "returns steps" do
      expect(
        CustomWizard::Builder.new(@wizard.id, user).build.steps.length
      ).to eq(2)
    end
    
    it 'returns no steps if multiple submissions are disabled and user has completed' do
      wizard_template = CustomWizard::Wizard.find(@wizard.id)
      wizard_template[:multiple_submissions] = false
      CustomWizard::Wizard.save(wizard_template)
      
      history_params = {
        action: UserHistory.actions[:custom_wizard_step],
        acting_user_id: user.id,
        context: @wizard.id
      }
      @wizard.steps.each do |step|
        UserHistory.create!(history_params.merge(subject: step.id))
      end
      
      built_wizard = CustomWizard::Builder.new(@wizard.id, user).build
      expect(
        CustomWizard::Builder.new(@wizard.id, user).build.steps.length
      ).to eq(0)
    end
    
    it 'returns no steps if user is not permitted' do
      expect(
        CustomWizard::Builder.new(@wizard.id, new_user).build.steps.length
      ).to eq(0)
    end
    
    it 'returns steps if user is permitted' do
      expect(
        CustomWizard::Builder.new(@wizard.id, user).build.steps.length
      ).to eq(3)
    end
    
    it 'returns a wizard with prefilled data if user has partially completed it' do
      expect(
        CustomWizard::Builder.new(@wizard.id, user)
          .build
          .steps[0].fields[0].value
      ).to eq('I am prefilled')
    end
    
    it 'returns a wizard with no prefilled data if options include reset' do
      PluginStore.set("super_mega_fun_wizard_submissions", user.id, {
        text: 'Input into text',
      })
      expect(
        CustomWizard::Builder.new(@wizard.id, user)
          .build(reset: true)
          .steps[0].fields[0].value
      ).to eq(nil)
    end
    
    context 'building steps' do
      it 'returns step metadata' do
        expect(
          CustomWizard::Builder.new(@wizard.id, user)
            .build(reset: true)
            .steps[0]
        ).to eq('Super Mega Fun Wizard')
      end
      
      it 'saves permitted params' do
        @wizard.steps[0].permitted_params = permitted_params
        built_wizard = CustomWizard::Builder.new(@wizard.id, user).build({}, param_key: 'param_value')
        submissions = PluginStore.get("super_mega_fun_wizard_submissions", user.id)
        expect(submissions[0]['submission_param_key']).to eq('param_value')
      end
      
      it 'is not permitted if required data is not present' do
        @wizard.steps[0].required_data = required_data
        expect(
          CustomWizard::Builder.new(@wizard.id, user).build.steps[0].permitted
        ).to eq(false)
      end
      
      it 'it shows required data message if required data has message' do
        @wizard.steps[0].required_data = required_data
        @wizard.steps[0].required_data_message = "Data is required"
        PluginStore.set("super_mega_fun_wizard_submissions", user.id,
          text: 'Input into text',
        )
        built_wizard = CustomWizard::Builder.new(@wizard.id, user).build
        expect(built_wizard.steps[0].permitted).to eq(false)
        expect(built_wizard.steps[0].permitted_message).to eq("Data is required")
      end
      
      it 'is permitted if required data is present' do
        @wizard.steps[0].required_data = required_data
        PluginStore.set('super_mega_fun_wizard_submissions', user.id,
          text: "Input into text"
        )
        expect(
          CustomWizard::Builder.new(@wizard.id, user).build.steps[0].permitted
        ).to eq(true)
      end
      
      it 'returns field metadata' do
        built_wizard = CustomWizard::Builder.new(@wizard.id, user).build
        expect(built_wizard.steps[0].fields[0].label).to eq("<p>Name</p>")
        expect(built_wizard.steps[0].fields[0].type).to eq("text")
      end
      
      it 'returns fields' do
        @wizard.steps[0].fields[1] = checkbox_field
        built_wizard = CustomWizard::Builder.new(@wizard.id, user).build
        expect(built_wizard.steps[0].fields.length).to eq(2)
      end
    end
    
    context 'on update' do
      it 'saves submissions' do
        built_wizard = CustomWizard::Builder.new(@wizard.id, user).build
        built_wizard.create_updater(built_wizard.steps[0].id,
          step_1_field_1: 'Text input'
        ).update
        expect(
          PluginStore.get("super_mega_fun_wizard_submissions", user.id)
            .first['step_1_field_1']
        ).to eq('Text input')
      end
      
      context 'validation' do
        it 'applies min length' do
          @wizard.steps[0].fields[0].min_length = 10
          built_wizard = CustomWizard::Builder.new(@wizard.id, user).build
          updater = built_wizard.create_updater(built_wizard.steps[0].id,
            step_1_field_1: 'Te'
          ).update
          expect(updater.errors.messages[:text].first).to eq(
            I18n.t('wizard.field.too_short', label: 'Text', min: 3)
          ) 
        end
        
        it 'standardises boolean entries' do
          @wizard.steps[0].fields[0] = checkbox_field
          built_wizard = CustomWizard::Builder.new(@wizard.id, user).build
          updater = built_wizard.create_updater(built_wizard.steps[1].id,
            step_2_field_5: 'false'
          ).update
          expect(
            PluginStore.get("super_mega_fun_wizard_submissions", user.id)
              .first['step_2_field_5']
          ).to eq(false)
        end
        
        it 'requires required fields' do
          @wizard.steps[0].fields[0]['required'] = true
          built_wizard = CustomWizard::Builder.new(@wizard.id, user).build
          updater = built_wizard.create_updater(built_wizard.steps.second.id).update
          expect(
            updater.errors.messages[:step_1_field_1].first
          ).to eq(I18n.t('wizard.field.required', label: 'Text')) 
        end
      end
    end
  end
end