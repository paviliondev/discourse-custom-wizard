# frozen_string_literal: true
require_relative '../../plugin_helper'

describe CustomWizard::Action do
  fab!(:user) { Fabricate(:user, name: "Angus", username: 'angus', email: "angus@email.com", trust_level: TrustLevel[2]) }
  fab!(:category) { Fabricate(:category, name: 'cat1', slug: 'cat-slug') }
  fab!(:group) { Fabricate(:group) }

  let(:wizard_template) {
    JSON.parse(
      File.open(
        "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
      ).read
    )
  }

  let(:open_composer) {
    JSON.parse(
      File.open(
        "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/actions/open_composer.json"
      ).read
    )
  }

  before do
    Group.refresh_automatic_group!(:trust_level_2)
    CustomWizard::Template.save(wizard_template, skip_jobs: true)
    @template = CustomWizard::Template.find('super_mega_fun_wizard')
  end

  context 'creating a topic' do
    it "works" do
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
      )
      expect(topic.exists?).to eq(true)
      expect(Post.where(
        topic_id: topic.pluck(:id),
        raw: "topic body"
      ).exists?).to eq(true)
    end

    it "fails silently without basic topic inputs" do
      wizard = CustomWizard::Builder.new(@template[:id], user).build
      wizard.create_updater(
        wizard.steps.first.id,
        step_1_field_2: "topic body"
      ).update
      wizard.create_updater(wizard.steps.second.id, {}).update
      updater = wizard.create_updater(wizard.steps.last.id, {})
      updater.update

      expect(updater.success?).to eq(true)
      expect(UserHistory.where(
        acting_user_id: user.id,
        context: "super_mega_fun_wizard",
        subject: "step_3"
      ).exists?).to eq(true)
      expect(Post.where(
        raw: "topic body"
      ).exists?).to eq(false)
    end

    it "adds custom fields" do
      wizard = CustomWizard::Builder.new(@template[:id], user).build
      wizard.create_updater(wizard.steps.first.id,
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
      topic_custom_field = TopicCustomField.where(
        name: "topic_field",
        value: "Topic custom field value",
        topic_id: topic.id
      )
      topic_json_custom_field = TopicCustomField.where("
        name = 'topic_json_field' AND
        (value::json->>'key_1') = 'Key 1 value' AND
        (value::json->>'key_2') = 'Key 2 value' AND
        topic_id = #{topic.id}"
      )
      post_custom_field = PostCustomField.where(
        name: "post_field",
        value: "Post custom field value",
        post_id: topic.first_post.id
      )
      expect(topic_custom_field.exists?).to eq(true)
      expect(topic_json_custom_field.exists?).to eq(true)
      expect(post_custom_field.exists?).to eq(true)
    end
  end

  context 'sending a message' do
    it 'works' do
      User.create(username: 'angus1', email: "angus1@email.com")

      wizard = CustomWizard::Builder.new(@template[:id], user).build
      wizard.create_updater(wizard.steps[0].id, {}).update
      wizard.create_updater(wizard.steps[1].id, {}).update

      topic = Topic.where(
        archetype: Archetype.private_message,
        title: "Message title"
      )

      post = Post.where(
        topic_id: topic.pluck(:id),
        raw: "I will interpolate some wizard fields"
      )

      expect(topic.exists?).to eq(true)
      expect(topic.first.topic_allowed_users.first.user.username).to eq('angus1')
      expect(post.exists?).to eq(true)
    end

    it 'allows using multiple PM targets' do
      User.create(username: 'angus1', email: "angus1@email.com")
      User.create(username: 'faiz', email: "faiz@email.com")
      Group.create(name: "cool_group")
      Group.create(name: 'cool_group_1')
      wizard = CustomWizard::Builder.new(@template[:id], user).build
      wizard.create_updater(wizard.steps[0].id, {}).update
      wizard.create_updater(wizard.steps[1].id, {}).update

      topic = Topic.where(
        archetype: Archetype.private_message,
        title: "Multiple Recipients title"
      )

      post = Post.where(
        topic_id: topic.pluck(:id),
        raw: "I will interpolate some wizard fields"
      )
      expect(topic.exists?).to eq(true)
      expect(topic.first.all_allowed_users.map(&:username)).to include('angus1', 'faiz')
      expect(topic.first.allowed_groups.map(&:name)).to include('cool_group', 'cool_group_1')
      expect(post.exists?).to eq(true)
    end
  end

  it 'updates a profile' do
    wizard = CustomWizard::Builder.new(@template[:id], user).build
    upload = Upload.create!(
      url: '/images/image.png',
      original_filename: 'image.png',
      filesize: 100,
      user_id: -1,
    )
    steps = wizard.steps
    wizard.create_updater(steps[0].id, {}).update
    wizard.create_updater(steps[1].id,
      step_2_field_7: upload.as_json
    ).update
    expect(user.profile_background_upload.id).to eq(upload.id)
  end

  context "open composer" do
    it 'works' do
      wizard = CustomWizard::Builder.new(@template[:id], user).build
      wizard.create_updater(wizard.steps[0].id, step_1_field_1: "Text input").update

      updater = wizard.create_updater(wizard.steps[1].id, {})
      updater.update

      category = Category.find_by(id: wizard.current_submission.fields['action_8'])

      expect(updater.result[:redirect_on_next]).to eq(
        "/new-topic?title=Title%20of%20the%20composer%20topic&body=I%20am%20interpolating%20some%20user%20fields%20Angus%20angus%20angus%40email.com&category_id=#{category.id}&tags=tag1"
      )
    end

    it 'encodes special characters in the title and body' do
      open_composer['title'][0]['output'] = "Title that's special $".dup
      open_composer['post_template'] = "Body & more body & more body".dup

      wizard = CustomWizard::Wizard.new(@template, user)
      action = CustomWizard::Action.new(
        wizard: wizard,
        action: open_composer,
        submission: wizard.current_submission
      )
      action.perform

      expect(action.result.success?).to eq(true)

      decoded_output = CGI.parse(URI.parse(action.result.output).query)

      expect(decoded_output['title'][0]).to eq("Title that's special $")
      expect(decoded_output['body'][0]).to eq("Body & more body & more body")
    end
  end

  it 'creates a category' do
    wizard = CustomWizard::Builder.new(@template[:id], user).build
    wizard.create_updater(wizard.steps[0].id, step_1_field_1: "Text input").update
    wizard.create_updater(wizard.steps[1].id, {}).update
    expect(Category.where(id: wizard.current_submission.fields['action_8']).exists?).to eq(true)
  end

  it 'creates a group' do
    wizard = CustomWizard::Builder.new(@template[:id], user).build
    wizard.create_updater(wizard.steps[0].id, step_1_field_1: "Text input").update
    expect(Group.where(name: wizard.current_submission.fields['action_9']).exists?).to eq(true)
  end

  it 'adds a user to a group' do
    wizard = CustomWizard::Builder.new(@template[:id], user).build
    step_id = wizard.steps[0].id
    updater = wizard.create_updater(step_id, step_1_field_1: "Text input").update
    group = Group.find_by(name: wizard.current_submission.fields['action_9'])
    expect(group.users.first.username).to eq('angus')
  end

  it 'watches categories' do
    wizard = CustomWizard::Builder.new(@template[:id], user).build
    wizard.create_updater(wizard.steps[0].id, step_1_field_1: "Text input").update
    wizard.create_updater(wizard.steps[1].id, {}).update
    expect(CategoryUser.where(
      category_id: wizard.current_submission.fields['action_8'],
      user_id: user.id
    ).first.notification_level).to eq(2)
    expect(CategoryUser.where(
      category_id: category.id,
      user_id: user.id
    ).first.notification_level).to eq(0)
  end

  it 're-routes a user' do
    wizard = CustomWizard::Builder.new(@template[:id], user).build
    updater = wizard.create_updater(wizard.steps.last.id, {})
    updater.update
    expect(updater.result[:redirect_on_next]).to eq("https://google.com")
  end
end
