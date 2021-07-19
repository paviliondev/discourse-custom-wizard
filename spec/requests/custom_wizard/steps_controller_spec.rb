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

  fab!(:user2) {
    Fabricate(
      :user,
      username: 'bob',
      email: "bob@email.com",
      trust_level: TrustLevel[2]
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

  let(:user_condition_template) {
    JSON.parse(
      File.open(
        "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/condition/user_condition.json"
      ).read
    )
  }

  let(:permitted_json) {
    JSON.parse(
      File.open(
        "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard/permitted.json"
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
    expect(wizard.current_submission.fields['step_1_field_1']).to eq("Text input")
  end

  context "raises an error" do
    it "when the wizard doesnt exist" do
      put '/w/not-super-mega-fun-wizard/steps/step_1.json'
      expect(response.status).to eq(400)
    end

    it "when the user cant access the wizard" do
      new_template = wizard_template.dup
      new_template["permitted"] = permitted_json["permitted"]
      CustomWizard::Template.save(new_template, skip_jobs: true)

      put '/w/super-mega-fun-wizard/steps/step_1.json'
      expect(response.status).to eq(403)
    end

    it "when the step doesnt exist" do
      put '/w/super-mega-fun-wizard/steps/step_10.json'
      expect(response.status).to eq(400)
    end

    it "when user cant see the step due to conditions" do
      sign_in(user2)

      new_wizard_template = wizard_template.dup
      new_wizard_template['steps'][0]['condition'] = user_condition_template['condition']
      CustomWizard::Template.save(new_wizard_template, skip_jobs: true)

      put '/w/super-mega-fun-wizard/steps/step_1.json'
      expect(response.status).to eq(403)
    end
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

    group_name = wizard.submissions.first.fields['action_9']
    group = Group.find_by(name: group_name)

    expect(group.present?).to eq(true)
    expect(group.full_name).to eq("My cool group")
  end

  it "returns a final step without conditions" do
    put '/w/super-mega-fun-wizard/steps/step_1.json'
    expect(response.status).to eq(200)
    expect(response.parsed_body['final']).to eq(false)

    put '/w/super-mega-fun-wizard/steps/step_2.json'
    expect(response.status).to eq(200)
    expect(response.parsed_body['final']).to eq(false)

    put '/w/super-mega-fun-wizard/steps/step_3.json'
    expect(response.status).to eq(200)
    expect(response.parsed_body['final']).to eq(true)
  end

  it "returns the correct final step when the conditional final step and last step are the same" do
    new_template = wizard_template.dup
    new_template['steps'][0]['condition'] = user_condition_template['condition']
    new_template['steps'][2]['condition'] = wizard_field_condition_template['condition']
    CustomWizard::Template.save(new_template, skip_jobs: true)

    put '/w/super-mega-fun-wizard/steps/step_1.json', params: {
      fields: {
        step_1_field_1: "Condition will pass"
      }
    }
    expect(response.status).to eq(200)
    expect(response.parsed_body['final']).to eq(false)

    put '/w/super-mega-fun-wizard/steps/step_2.json'
    expect(response.status).to eq(200)
    expect(response.parsed_body['final']).to eq(false)

    put '/w/super-mega-fun-wizard/steps/step_3.json'
    expect(response.status).to eq(200)
    expect(response.parsed_body['final']).to eq(true)
  end

  it "returns the correct final step when the conditional final step and last step are different" do
    new_template = wizard_template.dup
    new_template['steps'][2]['condition'] = wizard_field_condition_template['condition']
    CustomWizard::Template.save(new_template, skip_jobs: true)

    put '/w/super-mega-fun-wizard/steps/step_1.json', params: {
      fields: {
        step_1_field_1: "Condition will not pass"
      }
    }
    expect(response.status).to eq(200)
    expect(response.parsed_body['final']).to eq(false)

    put '/w/super-mega-fun-wizard/steps/step_2.json'
    expect(response.status).to eq(200)
    expect(response.parsed_body['final']).to eq(true)
  end

  it "returns the correct final step when the conditional final step is determined in the same action" do
    new_template = wizard_template.dup
    new_template['steps'][1]['condition'] = wizard_field_condition_template['condition']
    new_template['steps'][2]['condition'] = wizard_field_condition_template['condition']
    CustomWizard::Template.save(new_template, skip_jobs: true)

    put '/w/super-mega-fun-wizard/steps/step_1.json', params: {
      fields: {
        step_1_field_1: "Condition will not pass"
      }
    }
    expect(response.status).to eq(200)
    expect(response.parsed_body['final']).to eq(true)
  end

  it "excludes the non-included conditional fields from the submissions" do
    new_template = wizard_template.dup
    new_template['steps'][1]['fields'][0]['condition'] = wizard_field_condition_template['condition']
    CustomWizard::Template.save(new_template, skip_jobs: true)

    put '/w/super-mega-fun-wizard/steps/step_1.json', params: {
      fields: {
        step_1_field_1: "Condition will pass"
      }
    }

    put '/w/super-mega-fun-wizard/steps/step_2.json', params: {
      fields: {
        step_2_field_1: "1995-04-23"
      }
    }

    put '/w/super-mega-fun-wizard/steps/step_1.json', params: {
      fields: {
        step_1_field_1: "Condition will not pass"
      }
    }

    wizard_id = response.parsed_body['wizard']['id']
    wizard = CustomWizard::Wizard.create(wizard_id, user)
    submission = wizard.current_submission
    expect(submission.fields.keys).not_to include("step_2_field_1")
  end
end
