# frozen_string_literal: true
require_relative '../../plugin_helper'

describe CustomWizard::Builder do
  fab!(:trusted_user) {
    Fabricate(
      :user,
      username: 'angus',
      email: "angus@email.com",
      trust_level: TrustLevel[3]
    )
  }
  fab!(:user) { Fabricate(:user) }
  fab!(:category1) { Fabricate(:category, name: 'cat1') }
  fab!(:category2) { Fabricate(:category, name: 'cat2') }
  fab!(:group) { Fabricate(:group) }

  let(:required_data_json) {
    JSON.parse(
      File.open(
        "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/step/required_data.json"
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

  let(:permitted_param_json) {
    JSON.parse(
      File.open(
        "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/step/permitted_params.json"
      ).read
    )
  }

  let(:user_condition_json) {
    JSON.parse(
      File.open(
        "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/condition/user_condition.json"
      ).read
    )
  }

  let(:boolean_field_condition_json) {
    JSON.parse(
      File.open(
        "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/condition/boolean_field_condition.json"
      ).read
    )
  }

  before do
    Group.refresh_automatic_group!(:trust_level_3)
    CustomWizard::Template.save(
      JSON.parse(File.open(
        "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
      ).read),
    skip_jobs: true)
    @template = CustomWizard::Template.find('super_mega_fun_wizard')
  end

  context 'disabled' do
    before do
      SiteSetting.custom_wizard_enabled = false
    end

    it "returns nil" do
      expect(
        CustomWizard::Builder.new(@template[:id], user).build
      ).to eq(nil)
    end
  end

  context 'enabled' do
    before do
      SiteSetting.custom_wizard_enabled = true
    end

    it "returns wizard metadata" do
      wizard = CustomWizard::Builder.new(@template[:id], user).build
      expect(wizard.id).to eq("super_mega_fun_wizard")
      expect(wizard.name).to eq("Super Mega Fun Wizard")
      expect(wizard.background).to eq("#333333")
    end

    it "returns steps" do
      expect(
        CustomWizard::Builder.new(@template[:id], user).build
          .steps.length
      ).to eq(3)
    end

    context "with multiple submissions disabled" do
      before do
        @template[:multiple_submissions] = false
        CustomWizard::Template.save(@template.as_json)
      end

      it 'returns steps if user has not completed it' do
        expect(
          CustomWizard::Builder.new(@template[:id], user).build
            .steps.length
        ).to eq(3)
      end

      it 'returns no steps if user has completed it' do
        @template[:steps].each do |step|
          UserHistory.create!(
            {
              action: UserHistory.actions[:custom_wizard_step],
              acting_user_id: user.id,
              context: @template[:id]
            }.merge(
              subject: step[:id]
            )
          )
        end

        expect(
          CustomWizard::Builder.new(@template[:id], user).build
            .steps.length
        ).to eq(0)
      end
    end

    context "with restricted permissions" do
      before do
        @template[:permitted] = permitted_json["permitted"]
        CustomWizard::Template.save(@template.as_json)
      end

      it 'is not permitted if user is not in permitted group' do
        expect(
          CustomWizard::Builder.new(@template[:id], user).build
            .permitted?
        ).to eq(false)
      end

      it 'user cannot access if not permitted' do
        expect(
          CustomWizard::Builder.new(@template[:id], user).build
            .can_access?
        ).to eq(false)
      end

      it 'returns wizard metadata if user is not permitted' do
        expect(
          CustomWizard::Builder.new(@template[:id], user).build
            .name
        ).to eq("Super Mega Fun Wizard")
      end

      it 'returns no steps if user is not permitted' do
        expect(
          CustomWizard::Builder.new(@template[:id], user).build
            .steps.length
        ).to eq(0)
      end

      it 'is permitted if user is in permitted group' do
        expect(
          CustomWizard::Builder.new(@template[:id], trusted_user).build
            .permitted?
        ).to eq(true)
      end

      it 'user can access if permitted' do
        expect(
          CustomWizard::Builder.new(@template[:id], trusted_user).build
            .can_access?
        ).to eq(true)
      end

      it 'returns steps if user is permitted' do
        expect(
          CustomWizard::Builder.new(@template[:id], trusted_user).build
            .steps.length
        ).to eq(3)
      end
    end

    it 'returns prefilled data' do
      expect(
        CustomWizard::Builder.new(@template[:id], user).build
          .steps.first
          .fields.first
          .value
      ).to eq('I am prefilled')
    end

    context "user has partially completed" do
      before do
        wizard = CustomWizard::Wizard.new(@template, user)
        data = {
          step_1_field_1: 'I am a user submission'
        }
        CustomWizard::Submission.new(wizard, data).save
      end

      it 'returns saved submissions' do
        expect(
          CustomWizard::Builder.new(@template[:id], user).build
            .steps.first
            .fields.first
            .value
        ).to eq('I am a user submission')
      end

      context "restart is enabled" do
        before do
          @template[:restart_on_revisit] = true
          CustomWizard::Template.save(@template.as_json)
        end

        it 'does not return saved submissions' do
          expect(
            CustomWizard::Builder.new(@template[:id], user).build
              .steps.first
              .fields.first
              .value
          ).to eq('I am prefilled')
        end
      end
    end

    context 'building step' do
      it 'returns step metadata' do
        first_step = CustomWizard::Builder.new(@template[:id], user)
          .build(reset: true)
          .steps.first

        expect(first_step.id).to eq("step_1")
        expect(first_step.title).to eq("Text")
        expect(first_step.description).to eq("<p>Text inputs!</p>")
      end

      context 'with required data' do
        before do
          @template[:steps][0][:required_data] = required_data_json['required_data']
          @template[:steps][0][:required_data_message] = required_data_json['required_data_message']
          CustomWizard::Template.save(@template.as_json)
        end

        it 'is not permitted if required data is not present' do
          expect(
            CustomWizard::Builder.new(@template[:id], user).build
            .steps.first
            .permitted
          ).to eq(false)
        end

        it 'it shows required data message' do
          expect(
            CustomWizard::Builder.new(@template[:id], user).build
              .steps.first
              .permitted_message
          ).to eq("Missing required data")
        end

        it 'is permitted if required data is present' do
          wizard = CustomWizard::Wizard.create('super_mega_fun_wizard', user)
          CustomWizard::Submission.new(wizard, step_1_field_1: "required").save

          expect(
            CustomWizard::Builder.new(@template[:id], user).build
              .steps.first
              .permitted
          ).to eq(true)
        end
      end

      context "with permitted params" do
        before do
          @template[:steps][0][:permitted_params] = permitted_param_json['permitted_params']
          CustomWizard::Template.save(@template.as_json)
        end

        it 'saves permitted params' do
          wizard = CustomWizard::Builder.new(@template[:id], user).build({},
            param: 'param_value'
          )
          expect(wizard.current_submission.fields['saved_param']).to eq('param_value')
        end
      end

      context "with condition" do
        before do
          @template[:steps][0][:condition] = user_condition_json['condition']
          CustomWizard::Template.save(@template.as_json)
        end

        it "adds step when condition is passed" do
          wizard = CustomWizard::Builder.new(@template[:id], trusted_user).build
          expect(wizard.steps.first.id).to eq(@template[:steps][0]['id'])
        end

        it "does not add step when condition is not passed" do
          wizard = CustomWizard::Builder.new(@template[:id], user).build
          expect(wizard.steps.first.id).to eq(@template[:steps][1]['id'])
        end
      end
    end

    context 'building field' do
      it 'returns field metadata' do
        wizard = CustomWizard::Builder.new(@template[:id], user).build
        field = wizard.steps.first.fields.first

        expect(field.label).to eq("<p>Text</p>")
        expect(field.type).to eq("text")
        expect(field.id).to eq("step_1_field_1")
        expect(field.min_length).to eq("3")
      end

      it 'returns all step fields' do
        expect(
          CustomWizard::Builder.new(@template[:id], user)
            .build
            .steps.first
            .fields.length
        ).to eq(@template[:steps][0][:fields].length)
      end

      context "with condition" do
        before do
          @template[:steps][0][:fields][0][:condition] = user_condition_json['condition']
          @template[:steps][2][:fields][5][:condition] = boolean_field_condition_json['condition']
          CustomWizard::Template.save(@template.as_json)
        end

        it "adds field when condition is passed" do
          wizard = CustomWizard::Builder.new(@template[:id], trusted_user).build
          expect(wizard.steps.first.fields.first.id).to eq(@template[:steps][0][:fields][0]['id'])
        end

        it "does not add field when condition is not passed" do
          wizard = CustomWizard::Builder.new(@template[:id], user).build
          expect(wizard.steps.first.fields.first.id).to eq(@template[:steps][0][:fields][1]['id'])
        end

        it "works if a field condition uses 'is true/false'" do
          builder = CustomWizard::Builder.new(@template[:id], user)
          wizard = builder.build
          wizard.create_updater('step_2', step_2_field_5: 'true').update

          builder = CustomWizard::Builder.new(@template[:id], user)
          wizard = builder.build
          expect(wizard.steps.last.fields.last.id).to eq(@template[:steps][2][:fields][5]['id'])
        end
      end
    end

    context 'on update' do
      def perform_update(step_id, submission)
        updater = @wizard.create_updater(step_id, submission)
        updater.update
        updater
      end

      it 'saves submissions' do
        @wizard = CustomWizard::Builder.new(@template[:id], user).build
        perform_update('step_1', step_1_field_1: 'Text input')
        expect(@wizard.current_submission.fields['step_1_field_1']).to eq('Text input')
      end

      context 'save submissions disabled' do
        before do
          @template[:save_submissions] = false
          CustomWizard::Template.save(@template.as_json)
          @wizard = CustomWizard::Builder.new(@template[:id], user).build
        end

        it "does not save submissions" do
          perform_update('step_1', step_1_field_1: 'Text input')
          expect(@wizard.current_submission.present?).to eq(false)
        end
      end
    end
  end
end
