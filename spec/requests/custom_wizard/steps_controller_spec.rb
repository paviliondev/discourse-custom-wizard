# frozen_string_literal: true
require_relative '../../plugin_helper'

describe CustomWizard::StepsController do
  fab!(:user) {
    Fabricate(
      :user,
      username: 'angus',
      email: "angus@email.com",
      trust_level: TrustLevel[3]
    )
  }

  let(:wizard_template) {
    JSON.parse(
      File.open(
        "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
      ).read
    )
  }

  let(:wizard_field_condition_template) {
    JSON.parse(
      File.open(
        "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/condition/wizard_field_condition.json"
      ).read
    )
  }

  before do
    CustomWizard::Template.save(wizard_template, skip_jobs: true)
    sign_in(user)
  end

  it 'performs a step update' do
    put '/w/super-mega-fun-wizard/steps/step_1.json', params: {
      fields: {
        step_1_field_1: "Text input"
      }
    }
    expect(response.status).to eq(200)
    expect(response.parsed_body['wizard']['start']).to eq("step_2")

    wizard_id = response.parsed_body['wizard']['id']
    wizard = CustomWizard::Wizard.create(wizard_id, user)
    expect(wizard.submissions.last['step_1_field_1']).to eq("Text input")
  end

  it "works if the step has no fields" do
    put '/w/super-mega-fun-wizard/steps/step_1.json'
    expect(response.status).to eq(200)
    expect(response.parsed_body['wizard']['start']).to eq("step_2")
  end

  it "returns an updated wizard when condition passes" do
    new_template = wizard_template.dup
    new_template['steps'][1]['condition'] = wizard_field_condition_template['condition']
    CustomWizard::Template.save(new_template, skip_jobs: true)

    put '/w/super-mega-fun-wizard/steps/step_1.json', params: {
      fields: {
        step_1_field_1: "Condition will pass"
      }
    }
    expect(response.status).to eq(200)
    expect(response.parsed_body['wizard']['start']).to eq("step_2")
  end

  it "returns an updated wizard when condition doesnt pass" do
    new_template = wizard_template.dup
    new_template['steps'][1]['condition'] = wizard_field_condition_template['condition']
    CustomWizard::Template.save(new_template, skip_jobs: true)

    put '/w/super-mega-fun-wizard/steps/step_1.json', params: {
      fields: {
        step_1_field_1: "Condition wont pass"
      }
    }
    expect(response.status).to eq(200)
    expect(response.parsed_body['wizard']['start']).to eq("step_3")
  end
  
  it "runs completion actions if user has completed wizard" do
    new_template = wizard_template.dup
    
    ## route_to action
    new_template['actions'].last['run_after'] = 'wizard_completion'
    new_template['steps'][1]['condition'] = wizard_field_condition_template['condition']
    new_template['steps'][2]['condition'] = wizard_field_condition_template['condition']
    CustomWizard::Template.save(new_template, skip_jobs: true)

    put '/w/super-mega-fun-wizard/steps/step_1.json', params: {
      fields: {
        step_1_field_1: "Condition wont pass"
      }
    }
    expect(response.status).to eq(200)
    expect(response.parsed_body['redirect_on_complete']).to eq("https://google.com")
  end
  
  it "saves results of completion actions if user has completed wizard" do
    new_template = wizard_template.dup
    
    ## Create group action
    new_template['actions'].first['run_after'] = 'wizard_completion'
    new_template['steps'][1]['condition'] = wizard_field_condition_template['condition']
    CustomWizard::Template.save(new_template, skip_jobs: true)

    put '/w/super-mega-fun-wizard/steps/step_1.json', params: {
      fields: {
        step_1_field_1: "My cool group"
      }
    }
    expect(response.status).to eq(200)

    put '/w/super-mega-fun-wizard/steps/step_3.json'
    expect(response.status).to eq(200)
    
    wizard_id = response.parsed_body['wizard']['id']
    wizard = CustomWizard::Wizard.create(wizard_id, user)
    group_name = wizard.submissions.last['action_9']
    group = Group.find_by(name: group_name)
    expect(group.full_name).to eq("My cool group")
  end
  
  it "detects the final step correctly" do
    new_template = wizard_template.dup
    
    ## route_to action
    new_template['actions'].last['run_after'] = 'wizard_completion'
    new_template['steps'][1]['condition'] = wizard_field_condition_template['condition']
    new_template['steps'][2]['condition'] = wizard_field_condition_template['condition']

    CustomWizard::Template.save(new_template, skip_jobs: true)

    put '/w/super-mega-fun-wizard/steps/step_1.json', params: {
      fields: {
        step_1_field_1: "Condition will pass"
      }
    }
    expect(response.status).to eq(200)
    expect(response.parsed_body['final']).to eq(false)
    expect(response.parsed_body['next_step_id']).to eq(new_template['steps'][1]['id'])

    put '/w/super-mega-fun-wizard/steps/step_2.json', params: {
      fields: {
        step_1_field_1: "Condition will pass"
      }
    }
    expect(response.status).to eq(200)
    expect(response.parsed_body['final']).to eq(false)
    expect(response.parsed_body['next_step_id']).to eq(new_template['steps'][2]['id'])

    put '/w/super-mega-fun-wizard/steps/step_3.json'
    expect(response.status).to eq(200)
    expect(response.parsed_body['final']).to eq(true)
    expect(response.parsed_body['redirect_on_complete']).to eq("https://google.com")
  end
end
