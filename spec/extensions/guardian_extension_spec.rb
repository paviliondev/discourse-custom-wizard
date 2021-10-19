# frozen_string_literal: true
require_relative '../plugin_helper'

describe ::Guardian do
  fab!(:user) { 
    Fabricate(:user, name: "Angus", username: 'angus', email: "angus@email.com")
  }
  fab!(:category) { Fabricate(:category, name: 'cat1', slug: 'cat-slug') }
  let(:wizard_template) {
    JSON.parse(
      File.open(
        "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
      ).read
    )
  }

  before do
    CustomWizard::Template.save(wizard_template, skip_jobs: true)
    @template = CustomWizard::Template.find('super_mega_fun_wizard')
  end

  context "the user has access to creating wizard" do
    it "allows editing the topic first post" do
      wizard = CustomWizard::Builder.new(@template[:id], user).build

      wizard.create_updater(
        wizard.steps.first.id,
        step_1_field_1: "Topic Title",
        step_1_field_2: "topic body"
      ).update
      wizard.create_updater(wizard.steps.second.id, {}).update
      wizard.create_updater(wizard.steps.last.id,
        step_3_field_3: category.id
      ).update

      topic = Topic.where(
        title: "Topic Title",
        category_id: category.id
      ).first

      expect(user.guardian.send(:wizard_user_can_create_topic_on_category?, topic)).to be_truthy
    end
  end

  context "the user doesn't have access to creating wizard" do
    it "restricts editing the topic first post" do
      wizard = CustomWizard::Builder.new(@template[:id], user).build
      CustomWizard::Wizard.any_instance.stubs(:permitted?).returns(false)

      wizard.create_updater(
        wizard.steps.first.id,
        step_1_field_1: "Topic Title",
        step_1_field_2: "topic body"
      ).update
      wizard.create_updater(wizard.steps.second.id, {}).update
      wizard.create_updater(wizard.steps.last.id,
        step_3_field_3: category.id
      ).update

      topic = Topic.where(
        title: "Topic Title",
        category_id: category.id
      ).first

      expect(user.guardian.send(:wizard_user_can_create_topic_on_category?, topic)).to be_falsey
    end
  end
end
