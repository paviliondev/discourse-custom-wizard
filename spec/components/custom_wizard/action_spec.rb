# frozen_string_literal: true

describe CustomWizard::Action do
  fab!(:user) do
    Fabricate(
      :user,
      name: "Angus",
      username: "angus",
      email: "angus@email.com",
      trust_level: TrustLevel[2],
    )
  end
  fab!(:user1) do
    Fabricate(
      :user,
      name: "Angus One",
      username: "angus1",
      email: "angus_one@email.com",
      trust_level: TrustLevel[2],
    )
  end
  fab!(:category) { Fabricate(:category, name: "cat1", slug: "cat-slug") }
  fab!(:tag) { Fabricate(:tag, name: "tag1") }
  fab!(:group)

  let(:wizard_template) { get_wizard_fixture("wizard") }
  let(:open_composer) { get_wizard_fixture("actions/open_composer") }
  let(:create_category) { get_wizard_fixture("actions/create_category") }
  let(:watch_categories) { get_wizard_fixture("actions/watch_categories") }
  let(:watch_tags) { get_wizard_fixture("actions/watch_tags") }
  let(:create_group) { get_wizard_fixture("actions/create_group") }
  let(:create_group_with_nonexistent_user) { get_wizard_fixture("actions/create_group_bad_user") }
  let(:add_to_group) { get_wizard_fixture("actions/add_to_group") }
  let(:send_message) { get_wizard_fixture("actions/send_message") }
  let(:send_message_multi) { get_wizard_fixture("actions/send_message_multi") }
  let(:api_test_endpoint) { get_wizard_fixture("endpoints/test_endpoint") }
  let(:api_test_endpoint_body) { get_wizard_fixture("endpoints/test_endpoint_body") }
  let(:api_test_no_authorization) { get_wizard_fixture("api/no_authorization") }
  let(:guests_permitted) { get_wizard_fixture("wizard/guests_permitted") }

  def update_template(template)
    saved = CustomWizard::Template.new(template)
    raise saved.errors.full_messages.join(", ") if !saved.save(skip_jobs: true)
    @template = CustomWizard::Template.find("super_mega_fun_wizard")
  end

  let(:create_topic) do
    JSON.parse(
      File.open(
        "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/actions/create_topic.json",
      ).read,
    )
  end

  let(:custom_field_json) do
    JSON.parse(
      File.open(
        "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/custom_field/custom_fields.json",
      ).read,
    )
  end

  before do
    Group.refresh_automatic_group!(:trust_level_2)
    update_template(wizard_template)
  end

  describe "#create_topic" do
    def complete_wizard(body: "topic body", **last_step_fields)
      wizard = CustomWizard::Builder.new(@template[:id], user).build
      wizard.create_updater(
        wizard.steps.first.id,
        step_1_field_1: "Topic Title",
        step_1_field_2: body,
      ).update
      wizard.create_updater(wizard.steps.second.id, {}).update
      wizard.create_updater(
        wizard.steps.last.id,
        step_3_field_3: category.id,
        **last_step_fields,
      ).update
    end

    it "works" do
      complete_wizard

      topic = Topic.find_by(title: "Topic Title", category_id: category.id)
      expect(topic.first_post.raw).to eq("topic body")
    end

    it "redirects to the topic" do
      wizard_template[:actions][0]["skip_redirect"] = false
      update_template(wizard_template)
      complete_wizard

      submission = CustomWizard::Wizard.create(@template[:id], user).current_submission
      expect(submission.redirect_on_complete).to eq(Topic.find_by(title: "Topic Title").url)
    end

    def assign_category(output)
      wizard_template[:actions][0]["category"] = [
        { type: "assignment", output_type: "text", output_connector: "set", output: output },
      ]
      update_template(wizard_template)
    end

    it "ignores a category that doesn't exist" do
      assign_category("missing")

      complete_wizard

      topic = Topic.find_by(title: "Topic Title")
      expect(topic.category_id).to eq(SiteSetting.uncategorized_category_id)
    end

    it "uses a category given by slug" do
      assign_category(category.slug)

      complete_wizard

      topic = Topic.find_by(title: "Topic Title")
      expect(topic.category_id).to eq(category.id)
    end

    context "with tags" do
      fab!(:tag2) { Fabricate(:tag, name: "tag2") }

      let(:tag_field_input) do
        {
          type: "assignment",
          output_type: "wizard_field",
          output_connector: "set",
          output: "step_3_field_2",
        }
      end

      def text_input(output)
        { type: "assignment", output_type: "text", output_connector: "set", output: output }
      end

      def set_tag_inputs(*inputs)
        wizard_template[:actions][0]["tags"] = inputs
        wizard_template[:steps][2]["fields"] << { "id" => "step_3_field_2", "type" => "tag" }
        update_template(wizard_template)
      end

      def topic_tags
        Topic.find_by(title: "Topic Title").tags.pluck(:name)
      end

      it "adds tags mapped to tag objects" do
        set_tag_inputs(tag_field_input)

        complete_wizard(step_3_field_2: [{ id: tag.id, name: tag.name }])

        expect(topic_tags).to eq([tag.name])
      end

      it "adds comma separated tags from a text input" do
        set_tag_inputs(text_input("#{tag.name}, #{tag2.name},#{tag.name}"))

        complete_wizard

        expect(topic_tags).to contain_exactly(tag.name, tag2.name)
      end

      it "adds each tag of a list input" do
        set_tag_inputs(text_input("#{tag.name}\n#{tag2.name}").merge(output_type: "list"))

        complete_wizard

        expect(topic_tags).to contain_exactly(tag.name, tag2.name)
      end

      it "adds the tags of every input" do
        set_tag_inputs(tag_field_input, text_input(tag2.name))

        complete_wizard(step_3_field_2: [tag.name])

        expect(topic_tags).to contain_exactly(tag.name, tag2.name)
      end

      it "adds the fixed tag when the tag field is empty" do
        set_tag_inputs(tag_field_input, text_input(tag2.name))

        complete_wizard

        expect(topic_tags).to eq([tag2.name])
      end

      it "uses only the first matching input when an input is conditional" do
        set_tag_inputs(
          text_input(tag.name).merge(
            type: "conditional",
            output_connector: "then",
            pairs: [
              {
                index: 0,
                key: "name",
                key_type: "user_field",
                value: "Angus",
                value_type: "text",
                connector: "equal",
              },
            ],
          ),
          text_input(tag2.name),
        )

        complete_wizard

        expect(topic_tags).to eq([tag.name])
      end
    end

    it "queues the topic when it needs approval and keeps wizard data on approval" do
      category.update!(topic_posting_review_mode: :everyone)
      wizard_template["actions"][0]["visible"][0]["output"] = "false"
      update_template(wizard_template)

      complete_wizard
      expect(Topic.exists?(title: "Topic Title")).to eq(false)

      reviewable = ReviewableQueuedPost.find_by(target_created_by: user)
      reviewable.perform(Fabricate(:admin), :approve_post)

      topic = Topic.find_by(title: "Topic Title", category_id: category.id)
      expect(topic.visible).to eq(false)
      expect(topic.custom_fields["wizard_submission_id"]).to be_present
      expect(topic.custom_fields["topic_field"]).to eq("Topic custom field value")
      expect(topic.first_post.custom_fields["post_field"]).to eq("Post custom field value")
    end

    it "doesn't create a topic containing blocked words" do
      Fabricate(:watched_word, word: "forbidden", action: WatchedWord.actions[:block])

      complete_wizard(body: "forbidden body")

      expect(Topic.exists?(title: "Topic Title")).to eq(false)
    end

    it "fails silently without basic topic inputs" do
      wizard = CustomWizard::Builder.new(@template[:id], user).build
      wizard.create_updater(wizard.steps.first.id, step_1_field_2: "topic body").update
      wizard.create_updater(wizard.steps.second.id, {}).update
      updater = wizard.create_updater(wizard.steps.last.id, {})
      updater.update

      expect(updater.success?).to eq(true)
      expect(
        CustomWizard::UserHistory.where(
          actor_id: user.id,
          context: "super_mega_fun_wizard",
          subject: "step_3",
        ).exists?,
      ).to eq(true)
      expect(Post.where(raw: "topic body").exists?).to eq(false)
    end

    it "adds custom fields" do
      complete_wizard

      topic = Topic.where(title: "Topic Title", category_id: category.id).first
      topic_custom_field =
        TopicCustomField.where(
          name: "topic_field",
          value: "Topic custom field value",
          topic_id: topic.id,
        )
      topic_json_custom_field =
        TopicCustomField.where(
          "
        name = 'topic_json_field' AND
        (value::json->>'key_1') = 'Key 1 value' AND
        (value::json->>'key_2') = 'Key 2 value' AND
        topic_id = #{topic.id}",
        )
      post_custom_field =
        PostCustomField.where(
          name: "post_field",
          value: "Post custom field value",
          post_id: topic.first_post.id,
        )
      expect(topic_custom_field.exists?).to eq(true)
      expect(topic_json_custom_field.exists?).to eq(true)
      expect(post_custom_field.exists?).to eq(true)
    end

    it "adds registered custom fields" do
      custom_field = custom_field_json["custom_fields"][0]
      custom_field_name = custom_field["name"]
      custom_field_value = "Custom value"

      CustomWizard::CustomField.new(nil, custom_field).save
      create_topic["custom_fields"] = [
        {
          type: "association",
          pairs: [
            {
              index: 0,
              key: custom_field_name,
              key_type: "custom_field",
              value: custom_field_value,
              value_type: "text",
              connector: "association",
            },
          ],
        },
      ]

      wizard = CustomWizard::Wizard.new(@template, user)
      action =
        CustomWizard::Action.new(
          wizard: wizard,
          action: create_topic.with_indifferent_access,
          submission: wizard.current_submission,
        )
      action.perform

      expect(action.result.success?).to eq(true)
      expect(TopicCustomField.exists?(name: custom_field_name)).to eq(true)
    end

    it "allows poster to be set" do
      wizard_template[:actions][0]["poster"] = [
        { type: "assignment", output_type: "user", output_connector: "set", output: ["angus1"] },
      ]
      update_template(wizard_template)

      wizard = CustomWizard::Builder.new(@template[:id], user).build
      wizard.create_updater(
        wizard.steps.first.id,
        step_1_field_1: "Topic Title",
        step_1_field_2: "topic body",
      ).update
      wizard.create_updater(wizard.steps.second.id, {}).update
      wizard.create_updater(wizard.steps.last.id, step_3_field_3: category.id).update

      topic = Topic.where(title: "Topic Title", category_id: category.id)
      expect(topic.exists?).to eq(true)
      post = Post.find_by(topic_id: topic.pluck(:id), raw: "topic body")
      expect(post.present?).to eq(true)
      expect(post.user.username).to eq("angus1")
    end
  end

  it "updates a profile" do
    wizard = CustomWizard::Builder.new(@template[:id], user).build
    upload =
      Upload.create!(
        url: "/images/image.png",
        original_filename: "image.png",
        filesize: 100,
        user_id: -1,
      )
    steps = wizard.steps
    wizard.create_updater(steps[0].id, {}).update
    wizard.create_updater(
      steps[1].id,
      step_2_field_7: upload.as_json(only: %i[id url user_id]),
    ).update
    expect(user.profile_background_upload.id).to eq(upload.id)
  end

  context "open composer" do
    it "works" do
      wizard = CustomWizard::Builder.new(@template[:id], user).build
      wizard.create_updater(wizard.steps[0].id, step_1_field_1: "Text input").update

      updater = wizard.create_updater(wizard.steps[1].id, {})
      updater.update

      expect(updater.result[:redirect_on_next]).to eq(
        "/new-topic?title=Title%20of%20the%20composer%20topic&body=I%20am%20interpolating%20some%20user%20fields%20Angus%20angus%20angus%40email.com&tags=tag1",
      )
    end

    def composer_query
      wizard = CustomWizard::Wizard.new(@template, user)
      action =
        CustomWizard::Action.new(
          wizard: wizard,
          action: open_composer,
          submission: wizard.current_submission,
        )
      action.perform

      expect(action.result.success?).to eq(true)

      CGI.parse(URI.parse(action.result.output).query)
    end

    it "encodes special characters in the title and body" do
      open_composer["title"][0]["output"] = "Title that's special $".dup
      open_composer["post_template"] = "Body & more body & more body".dup

      query = composer_query

      expect(query["title"]).to eq(["Title that's special $"])
      expect(query["body"]).to eq(["Body & more body & more body"])
    end

    it "encodes special characters in tags" do
      open_composer["tags"] = [
        {
          type: "assignment",
          output_type: "text",
          output_connector: "set",
          output: "#{tag.name},x&category_id=99",
        },
      ]

      query = composer_query

      expect(query["tags"]).to eq(["#{tag.name},x&category_id=99"])
    end
  end

  context "route to action" do
    it "re-routes a user" do
      wizard = CustomWizard::Builder.new(@template[:id], user).build
      updater = wizard.create_updater(wizard.steps.last.id, {})
      updater.update
      expect(updater.result[:redirect_on_next]).to eq("https://google.com")
    end

    it "works if the code field has a blank string" do
      wizard_template[:actions].last[:code] = " "
      update_template(wizard_template)

      wizard = CustomWizard::Builder.new(@template[:id], user).build
      updater = wizard.create_updater(wizard.steps.last.id, {})
      updater.update
      expect(updater.result[:redirect_on_next]).to eq("https://google.com")
    end
  end

  context "standard actions" do
    before { Jobs.run_immediately! }

    let(:step_1_field_1_input) do
      {
        type: "assignment",
        output_type: "wizard_field",
        output_connector: "set",
        output: "step_1_field_1",
      }
    end

    def run_action(action, step_1_field_1: "Text input")
      wizard_template[:actions] << action
      update_template(wizard_template)

      wizard = CustomWizard::Builder.new(@template[:id], user).build
      wizard.create_updater(wizard.steps[0].id, step_1_field_1: step_1_field_1).update
    end

    def tag_level(tag)
      TagUser.find_by(tag: tag, user: user)&.notification_level
    end

    def category_level(category)
      CategoryUser.find_by(category: category, user: user)&.notification_level
    end

    it "watches tags" do
      watch_tags[:tags][0][:output] = tag.name
      run_action(watch_tags)

      expect(tag_level(tag)).to eq(TagUser.notification_levels[:tracking])
    end

    it "watches tags mapped to tag objects" do
      watch_tags[:tags] = [step_1_field_1_input]
      run_action(watch_tags, step_1_field_1: [{ id: tag.id, name: tag.name }])

      expect(tag_level(tag)).to eq(TagUser.notification_levels[:tracking])
    end

    it "watches tags for the users in the action" do
      user2 = Fabricate(:user, username: "angus2")

      watch_tags[:tags][0][:output] = tag.name
      watch_tags[:wizard_user] = false
      watch_tags[:usernames] = [
        {
          type: "assignment",
          output_type: "user",
          output_connector: "set",
          output: [user1.username, user2.username],
        },
      ]
      run_action(watch_tags)

      expect(TagUser.where(tag_id: tag.id, notification_level: 2).pluck(:user_id)).to match_array(
        [user1.id, user2.id],
      )
    end

    it "doesn't watch tags when no notification level is set" do
      watch_tags[:tags][0][:output] = tag.name
      watch_tags[:notification_level] = nil
      run_action(watch_tags)

      expect(tag_level(tag)).to be_nil
    end

    { "blank" => "", "not found" => "missing" }.each do |description, value|
      it "keeps watched tags when the tags are #{description}" do
        TagUser.change(user, tag.id, TagUser.notification_levels[:tracking])
        watch_tags[:tags] = [step_1_field_1_input]
        run_action(watch_tags, step_1_field_1: value)

        expect(tag_level(tag)).to eq(TagUser.notification_levels[:tracking])
        expect(CustomWizard::Log.list.logs.first.message).to include("tags not found")
      end
    end

    it "watches categories" do
      watch_categories[:categories][0][:output] = category.id
      run_action(watch_categories)

      expect(category_level(category)).to eq(CategoryUser.notification_levels[:tracking])
    end

    it "watches categories given by slug" do
      watch_categories[:categories][0][:output] = category.slug
      run_action(watch_categories)

      expect(category_level(category)).to eq(CategoryUser.notification_levels[:tracking])
    end

    it "mutes the other categories when no category is given" do
      run_action(watch_categories)

      expect(category_level(category)).to eq(CategoryUser.notification_levels[:muted])
    end

    it "doesn't mute categories when no category is found" do
      watch_categories[:categories][0][:output] = "missing"
      run_action(watch_categories)

      expect(CategoryUser.where(user: user)).to be_empty
    end

    it "watches categories for the users in the action" do
      user2 = Fabricate(:user, username: "angus2")

      watch_categories[:categories][0][:output] = category.id
      watch_categories[:wizard_user] = false
      watch_categories[:usernames] = [
        {
          type: "assignment",
          output_type: "user",
          output_connector: "set",
          output: [user1.username, user2.username],
        },
      ]
      run_action(watch_categories)

      expect(
        CategoryUser.where(category_id: category.id, notification_level: 2).pluck(:user_id),
      ).to match_array([user1.id, user2.id])
    end

    it "watches the categories of every category input for the users of every user input" do
      category2 = Fabricate(:category)
      user2 = Fabricate(:user)

      watch_categories[:categories] = [category, category2].map do |c|
        { type: "assignment", output_type: "category", output_connector: "set", output: [c.id] }
      end
      watch_categories[:wizard_user] = false
      watch_categories[:usernames] = [user1, user2].map do |u|
        { type: "assignment", output_type: "user", output_connector: "set", output: [u.username] }
      end
      run_action(watch_categories)

      expect(
        CategoryUser.where(notification_level: 2).pluck(:user_id, :category_id),
      ).to match_array([user1, user2].product([category, category2]).map { |u, c| [u.id, c.id] })
    end

    it "#send_message" do
      Jobs.run_immediately!

      target_user = Fabricate(:user)

      send_message["recipient"][0]["output"][0] = target_user.username
      wizard_template["actions"] << send_message
      update_template(wizard_template)

      wizard = CustomWizard::Builder.new(@template[:id], user).build
      wizard.create_updater(wizard.steps[0].id, {}).update
      wizard.create_updater(wizard.steps[1].id, {}).update

      topic = Topic.where(archetype: Archetype.private_message, title: "Message title")

      post = Post.where(topic_id: topic.pluck(:id), raw: "I will interpolate some wizard fields")

      expect(topic.exists?).to eq(true)
      expect(topic.first.topic_allowed_users.first.user.username).to eq(target_user.username)
      expect(post.exists?).to eq(true)
      expect(target_user.reload.notifications.count).to eq(1)
    end

    it "#send_message doesn't send messages containing blocked words" do
      Fabricate(:watched_word, word: "interpolate", action: WatchedWord.actions[:block])
      wizard_template["actions"] << send_message
      update_template(wizard_template)

      wizard = CustomWizard::Builder.new(@template[:id], user).build
      wizard.create_updater(wizard.steps[0].id, {}).update
      wizard.create_updater(wizard.steps[1].id, {}).update

      expect(Topic.exists?(title: "Message title")).to eq(false)
    end

    it "#send_message allows using multiple targets" do
      Jobs.run_immediately!

      user1 = Fabricate(:user)
      user2 = Fabricate(:user)
      group1 = Fabricate(:group)
      group2 = Fabricate(:group)

      send_message_multi["recipient"][0]["output"] = [
        user1.username,
        user2.username,
        group1.name,
        group2.name,
      ]
      wizard_template["actions"] << send_message_multi
      update_template(wizard_template)
      update_template(wizard_template)

      wizard = CustomWizard::Builder.new(@template[:id], user).build
      wizard.create_updater(wizard.steps[0].id, {}).update
      wizard.create_updater(wizard.steps[1].id, {}).update

      topic = Topic.where(archetype: Archetype.private_message, title: "Multiple Recipients title")

      post = Post.where(topic_id: topic.pluck(:id), raw: "I will interpolate some wizard fields")

      expect(topic.exists?).to eq(true)
      expect(topic.first.all_allowed_users.map(&:username)).to include(
        user1.username,
        user2.username,
      )
      expect(topic.first.allowed_groups.map(&:name)).to include(group1.name, group2.name)
      expect(post.exists?).to eq(true)
      expect(user1.reload.notifications.count).to eq(1)
      expect(user2.reload.notifications.count).to eq(1)
    end

    it "#send_message sends to the recipients of every recipient input" do
      send_message_multi["recipient"] = [
        step_1_field_1_input,
        {
          type: "assignment",
          output_type: "user",
          output_connector: "set",
          output: [user1.username],
        },
        { type: "assignment", output_type: "text", output_connector: "set", output: group.name },
        {
          type: "assignment",
          output_type: "text",
          output_connector: "set",
          output: user1.username.upcase,
        },
      ]
      wizard_template["actions"] << send_message_multi
      update_template(wizard_template)

      wizard = CustomWizard::Builder.new(@template[:id], user).build
      wizard.create_updater(wizard.steps[0].id, {}).update
      wizard.create_updater(wizard.steps[1].id, {}).update

      topic =
        Topic.find_by!(archetype: Archetype.private_message, title: "Multiple Recipients title")
      expect(topic.allowed_users).to include(user1)
      expect(topic.allowed_groups).to contain_exactly(group)
    end

    it "#send_message sends to the group in a group field" do
      wizard_template[:steps][0][:fields] << { id: "step_1_field_5", type: "group" }.as_json
      send_message["recipient"] = [step_1_field_1_input.merge(output: "step_1_field_5")]
      wizard_template["actions"] << send_message
      update_template(wizard_template)

      wizard = CustomWizard::Builder.new(@template[:id], user).build
      wizard.create_updater(wizard.steps[0].id, step_1_field_5: group.id).update
      wizard = CustomWizard::Builder.new(@template[:id], user).build
      wizard.create_updater(wizard.steps[1].id, {}).update

      topic = Topic.find_by!(archetype: Archetype.private_message, title: "Message title")
      expect(topic.allowed_groups).to contain_exactly(group)
    end

    it "#send_message sends to each recipient in a comma separated value" do
      send_message["recipient"] = [step_1_field_1_input]
      wizard_template["actions"] << send_message
      update_template(wizard_template)

      wizard = CustomWizard::Builder.new(@template[:id], user).build
      wizard.create_updater(
        wizard.steps[0].id,
        step_1_field_1: "#{user1.username},#{group.name}",
      ).update
      wizard.create_updater(wizard.steps[1].id, {}).update

      topic = Topic.find_by!(archetype: Archetype.private_message, title: "Message title")
      expect(topic.allowed_users).to include(user1)
      expect(topic.allowed_groups).to contain_exactly(group)
    end

    context "with a guest" do
      describe "#create_topic" do
        before do
          Jobs.run_immediately!

          wizard_template["permitted"] = guests_permitted["permitted"]
          wizard_template[:steps][0][:fields] << {
            id: "step_1_field_5",
            label: "Guest Email",
            type: "text",
            min_length: "3",
          }.as_json
          create_topic["run_after"] = "step_3"
          create_topic["guest_email"] = [
            {
              type: "assignment",
              output: "step_1_field_5",
              output_type: "wizard_field",
              output_connector: "set",
            },
          ]
          create_topic["category"] = [
            {
              type: "assignment",
              output: "step_3_field_3",
              output_type: "wizard_field",
              output_connector: "set",
            },
          ]
          wizard_template.delete("actions")
          wizard_template[:actions] = [create_topic]

          update_template(wizard_template)
        end

        def complete_as_guest(email)
          wizard =
            CustomWizard::Builder.new(
              @template[:id],
              nil,
              CustomWizard::Wizard.generate_guest_id,
            ).build
          wizard.create_updater(wizard.steps.first.id, step_1_field_5: email).update
          wizard.create_updater(wizard.steps.second.id, {}).update
          wizard.create_updater(wizard.steps.last.id, step_3_field_3: category.id).update
          Topic.find_by(category_id: category.id)
        end

        it "creates a staged guest poster if guest_email is set" do
          poster = complete_as_guest("guest@email.com").user
          expect(poster.staged).to eq(true)
          expect(poster.primary_email.email).to eq("guest@email.com")
        end

        it "reuses a staged user with the same email" do
          staged = Fabricate(:staged, email: "guest@email.com")
          expect(complete_as_guest("guest@email.com").user).to eq(staged)
        end

        it "does not post as a registered user with the same email" do
          Fabricate(:admin, email: "guest@email.com")
          expect(complete_as_guest("guest@email.com")).to be_nil
        end

        it "posts as the system user when the guest email is invalid" do
          expect(complete_as_guest("not-an-email").user).to eq(Discourse.system_user)
        end
      end

      describe "#send_message" do
        it "works" do
          wizard_template["permitted"] = guests_permitted["permitted"]
          wizard_template.delete("actions")
          wizard_template["actions"] = [send_message]
          update_template(wizard_template)

          wizard =
            CustomWizard::Builder.new(
              wizard_template["id"],
              nil,
              CustomWizard::Wizard.generate_guest_id,
            ).build
          wizard.create_updater(wizard.steps[0].id, {}).update
          updater = wizard.create_updater(wizard.steps[1].id, {})
          updater.update

          topic = Topic.where(archetype: Archetype.private_message, title: "Message title")
          post = Post.where(topic_id: topic.pluck(:id))

          expect(topic.exists?).to eq(true)
          expect(topic.first.topic_allowed_users.first.user.username).to eq(user1.username)
          expect(topic.first.topic_allowed_users.second.user.username).to eq(
            Discourse.system_user.username,
          )
          expect(post.exists?).to eq(true)
        end

        it "works when the target is an email address" do
          Jobs.run_immediately!

          wizard_template["permitted"] = guests_permitted["permitted"]
          wizard_template.delete("actions")

          send_message["recipient"] = [step_1_field_1_input]

          wizard_template["actions"] = [send_message]
          update_template(wizard_template)

          NotificationEmailer.expects(:process_notification).once

          wizard =
            CustomWizard::Builder.new(
              wizard_template["id"],
              nil,
              CustomWizard::Wizard.generate_guest_id,
            ).build
          wizard.create_updater(wizard.steps[0].id, step_1_field_1: "guest@email.com").update
          updater = wizard.create_updater(wizard.steps[1].id, {})
          updater.update

          topic = Topic.where(archetype: Archetype.private_message, title: "Message title")
          post = Post.where(topic_id: topic.pluck(:id))

          expect(topic.exists?).to eq(true)
          expect(topic.first.topic_allowed_users.first.user.staged).to eq(true)
          expect(topic.first.topic_allowed_users.first.user.primary_email.email).to eq(
            "guest@email.com",
          )
          expect(topic.first.topic_allowed_users.second.user.username).to eq(
            Discourse.system_user.username,
          )
          expect(post.exists?).to eq(true)
        end
      end

      it "skips an action that needs a user" do
        wizard = CustomWizard::Wizard.new(@template, nil, CustomWizard::Wizard.generate_guest_id)
        action =
          CustomWizard::Action.new(
            wizard: wizard,
            action: watch_tags,
            submission: wizard.current_submission,
          )

        expect(action.perform.success?).to eq(false)

        log = CustomWizard::Log.list.logs.first
        expect(log.message).to include("action requires user")
        expect(log.username).to eq(wizard.guest_id)
      end
    end
  end

  context "business actions" do
    def run_create_category
      wizard_template["actions"] << create_category
      wizard_template["actions"] << create_group
      update_template(wizard_template)

      wizard = CustomWizard::Builder.new(@template[:id], user).build
      wizard.create_updater(wizard.steps[0].id, step_1_field_1: "Text input").update
      wizard.create_updater(wizard.steps[1].id, {}).update

      Category.find_by(id: wizard.current_submission.fields["action_8"])
    end

    it "#create_category" do
      expect(run_create_category).to be_present
    end

    it "#create_category uses a parent category given by slug" do
      create_category["parent_category_id"] = [
        { type: "assignment", output_type: "text", output_connector: "set", output: category.slug },
      ]

      expect(run_create_category.parent_category_id).to eq(category.id)
    end

    it "#create_group" do
      wizard_template["actions"] << create_group
      update_template(wizard_template)

      wizard = CustomWizard::Builder.new(@template[:id], user).build
      wizard.create_updater(wizard.steps[0].id, step_1_field_1: "Text input").update

      group_id = Group.where(name: wizard.current_submission.fields["action_9"]).first.id
      user_id =
        User.find_by(username: wizard_template["actions"][4]["usernames"][0]["output"][0]).id

      expect(Group.where(name: wizard.current_submission.fields["action_9"]).exists?).to eq(true)
      expect(GroupUser.where(group_id: group_id, user_id: user_id).exists?).to eq(true)
    end

    it "#create_group completes successfully when user included in usernames does not exist but excludes users who do not exist and includes warning in log" do
      wizard_template["actions"] << create_group_with_nonexistent_user
      update_template(wizard_template)

      wizard = CustomWizard::Builder.new(@template[:id], user).build
      wizard.create_updater(wizard.steps[0].id, step_1_field_1: "Text input").update

      group_id = Group.where(name: wizard.current_submission.fields["action_9"]).first.id

      expect(
        CustomWizard::Log.list_query.all.last.value.include? "some users were not found"
      ).to eq(true)
      expect(Group.where(name: wizard.current_submission.fields["action_9"]).exists?).to eq(true)
      expect(GroupUser.where(group_id: group_id).count).to eq(1)
    end

    it "#create_group adds the users of every username input" do
      user2 = Fabricate(:user)
      create_group["usernames"] = [
        {
          type: "assignment",
          output_type: "text",
          output_connector: "set",
          output: user2.username.upcase,
        },
        {
          type: "assignment",
          output_type: "user",
          output_connector: "set",
          output: [user1.username],
        },
      ]
      wizard_template["actions"] << create_group
      update_template(wizard_template)

      wizard = CustomWizard::Builder.new(@template[:id], user).build
      wizard.create_updater(wizard.steps[0].id, step_1_field_1: "Text input").update

      group = Group.find_by!(name: wizard.current_submission.fields["action_9"])
      expect(group.users).to contain_exactly(user, user1, user2)
      expect(group.group_users.where(owner: true).pluck(:user_id)).to eq([user.id])
    end

    it "#add_to_group" do
      wizard_template["actions"] << create_group
      wizard_template["actions"] << add_to_group
      update_template(wizard_template)

      wizard = CustomWizard::Builder.new(@template[:id], user).build
      step_id = wizard.steps[0].id
      updater = wizard.create_updater(step_id, step_1_field_1: "Text input").update
      group = Group.find_by(name: wizard.current_submission.fields["action_9"])

      expect(group.users.first.username).to eq("angus")
    end

    it "#add_to_group doesn't add users to automatic groups" do
      add_to_group["group"] = [
        {
          type: "assignment",
          output: "trust_level_4",
          output_type: "text",
          output_connector: "set",
        },
      ]
      wizard_template["actions"] << add_to_group
      update_template(wizard_template)

      wizard = CustomWizard::Builder.new(@template[:id], user).build
      wizard.create_updater(wizard.steps[0].id, step_1_field_1: "Text input").update

      expect(Group[:trust_level_4].users).not_to include(user)
    end

    it "#send_to_api successful" do
      stub_request(:put, "https://myexternalapi.com/update").with(
        body: "some_body",
        headers: {
          "Host" => "myexternalapi.com",
        },
      ).to_return(status: 200, body: "success", headers: {})

      new_api = CustomWizard::Api.new("my_api")
      CustomWizard::Api.set("my_api", title: "Mocked external api")
      CustomWizard::Api::Authorization.set("my_api", api_test_no_authorization)
      CustomWizard::Api::Endpoint.new("my_api")
      CustomWizard::Api::Endpoint.set("my_api", api_test_endpoint)
      endpoint_id = CustomWizard::Api::Endpoint.list("my_api").first.id

      result = CustomWizard::Api::Endpoint.request("my_api", endpoint_id, "some_body")
      log_entry = CustomWizard::Api::LogEntry.list("my_api").first

      expect(result).to eq("success")
      expect(log_entry.status).to eq("SUCCESS")
    end

    it "#send_to_api failure" do
      stub_request(:put, "https://myexternalapi.com/update").with(
        body: "some_body",
        headers: {
          "Host" => "myexternalapi.com",
        },
      ).to_return(status: 500, body: "failure", headers: {})

      new_api = CustomWizard::Api.new("my_api")
      CustomWizard::Api.set("my_api", title: "Mocked external api")
      CustomWizard::Api::Authorization.set("my_api", api_test_no_authorization)
      CustomWizard::Api::Endpoint.new("my_api")
      CustomWizard::Api::Endpoint.set("my_api", api_test_endpoint)
      endpoint_id = CustomWizard::Api::Endpoint.list("my_api").first.id

      result = CustomWizard::Api::Endpoint.request("my_api", endpoint_id, "some_body")
      log_entry = CustomWizard::Api::LogEntry.list("my_api").first

      expect(result).to eq({ error: "API request failed" })
      expect(log_entry.status).to eq("FAIL")
    end
  end

  it "registers callbacks" do
    described_class.register_callback(:before_create_topic) do |params, wizard, action, submission|
      params[:topic_opts][:custom_fields]["topic_custom_field"] = true
      params
    end

    wizard = CustomWizard::Builder.new(@template[:id], user).build
    action =
      CustomWizard::Action.new(
        wizard: wizard,
        action: create_topic.with_indifferent_access,
        submission: wizard.current_submission,
      )
    action.perform

    expect(action.result.success?).to eq(true)
    expect(Topic.find(action.result.output).custom_fields["topic_custom_field"]).to eq("t")
  end

  context "creating a topic when there are multiple actions" do
    it "works" do
      wizard_template["actions"] << create_topic
      wizard_template["actions"] << send_message
      update_template(wizard_template)
      wizard = CustomWizard::Builder.new(@template[:id], user).build
      wizard.create_updater(
        wizard.steps.first.id,
        step_1_field_1: "Topic Title",
        step_1_field_2: "topic body",
      ).update
      wizard.create_updater(wizard.steps.second.id, {}).update
      wizard.create_updater(wizard.steps.last.id, step_3_field_3: category.id).update
      wizard.create_updater(wizard.steps[0].id, {}).update
      wizard.create_updater(wizard.steps[1].id, {}).update
      topic = Topic.where(title: "Topic Title", category_id: category.id)
      expect(topic.exists?).to eq(true)
      expect(Post.where(topic_id: topic.pluck(:id), raw: "topic body").exists?).to eq(true)
    end
  end
end
