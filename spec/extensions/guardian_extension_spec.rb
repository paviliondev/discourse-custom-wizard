# frozen_string_literal: true

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

  def create_topic_by_wizard(wizard)
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

    topic
  end

  before do
    CustomWizard::Template.save(wizard_template, skip_jobs: true)
    @template = CustomWizard::Template.find('super_mega_fun_wizard')
  end

  context "topic created by user using wizard" do
    it "allows editing the topic first post" do
      wizard = CustomWizard::Builder.new(@template[:id], user).build
      topic = create_topic_by_wizard(wizard)
      expect(user.guardian.wizard_can_edit_topic?(topic)).to be_truthy
    end
  end

  context "topic created by user without wizard" do
    it "restricts editing the topic first post" do
      topic_params = {
        title: "Topic Title",
        raw: "Topic body",
        skip_validations: true
      }
      post = PostCreator.new(user, topic_params).create
      expect(user.guardian.wizard_can_edit_topic?(post.topic)).to be_falsey
    end
  end
end
