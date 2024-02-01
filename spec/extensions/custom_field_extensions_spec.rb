# frozen_string_literal: true

describe "custom field extensions" do
  fab!(:topic) { Fabricate(:topic) }
  fab!(:post) { Fabricate(:post) }
  fab!(:category) { Fabricate(:category) }
  fab!(:group) { Fabricate(:group) }
  fab!(:user) { Fabricate(:user) }

  let(:custom_field_json) { get_wizard_fixture("custom_field/custom_fields") }
  let(:subscription_custom_field_json) { get_wizard_fixture("custom_field/subscription_custom_fields") }

  before do
    custom_field_json['custom_fields'].each do |field_json|
      custom_field = CustomWizard::CustomField.new(nil, field_json)
      custom_field.save
    end
  end

  context "topic" do
    it "registers topic custom fields" do
      topic
      expect(Topic.get_custom_field_descriptor("topic_field_1").type).to eq(:boolean)
    end

    it "adds topic custom fields to the topic_view serializer" do
      topic.custom_fields["topic_field_1"] = true
      topic.save_custom_fields(true)

      serializer = TopicViewSerializer.new(
        TopicView.new(topic.id, user),
        scope: Guardian.new(user),
        root: false
      ).as_json

      expect(serializer[:topic_field_1]).to eq(true)
    end

    it "adds topic custom fields to the topic_list_item serializer" do
      topic.custom_fields["topic_field_1"] = true
      topic.save_custom_fields(true)

      serializer = TopicListItemSerializer.new(
        topic,
        scope: Guardian.new(user),
        root: false
      ).as_json

      expect(serializer[:topic_field_1]).to eq(true)
    end
  end

  context "post" do
    it "registers post custom fields" do
      post
      expect(Post.get_custom_field_descriptor("post_field_1").type).to eq(:integer)
    end

    it "adds post custom fields to the post serializer" do
      post.custom_fields["post_field_1"] = 7
      post.save_custom_fields(true)

      serializer = PostSerializer.new(
        post,
        scope: Guardian.new(user),
        root: false
      ).as_json

      expect(serializer[:post_field_1]).to eq(7)
    end
  end

  context "subscription custom fields" do
    before do
      enable_subscription("business")

      subscription_custom_field_json['custom_fields'].each do |field_json|
        custom_field = CustomWizard::CustomField.new(nil, field_json)
        custom_field.save
      end
    end

    context "category" do
      it "registers" do
        category
        expect(Category.get_custom_field_descriptor("category_field_1").type).to eq(:json)
      end

      it "adds custom fields to the basic category serializer" do
        category.custom_fields["category_field_1"] = { a: 1, b: 2 }.to_json
        category.save_custom_fields(true)

        serializer = BasicCategorySerializer.new(
          category,
          scope: Guardian.new(user),
          root: false
        ).as_json

        expect(serializer[:category_field_1]).to eq({ a: 1, b: 2 }.to_json)
      end
    end

    context "group" do
      it "registers" do
        group
        expect(Group.get_custom_field_descriptor("group_field_1").type).to eq(:string)
      end

      it "adds custom fields to the basic group serializer" do
        group.custom_fields["group_field_1"] = "Hello"
        group.save_custom_fields(true)

        serializer = BasicGroupSerializer.new(
          group,
          scope: Guardian.new(user),
          root: false
        ).as_json

        expect(serializer[:group_field_1]).to eq("Hello")
      end
    end
  end
end
