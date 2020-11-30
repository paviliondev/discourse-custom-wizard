# frozen_string_literal: true

require_relative '../plugin_helper'

describe "custom field extensions" do
  fab!(:topic) { Fabricate(:topic) }
  fab!(:post) { Fabricate(:post) }
  fab!(:category) { Fabricate(:category) }
  fab!(:group) { Fabricate(:group) }
  fab!(:user) { Fabricate(:user) }
  
  let(:custom_field_json) {
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/custom_field/custom_fields.json"
    ).read)
  }
  
  before do
    custom_field_json['custom_fields'].each do |field_json|
      custom_field = CustomWizard::CustomField.new(nil, field_json)
      custom_field.save
    end
  end
  
  context "topic" do
    it "registers topic custom fields" do
      topic
      expect(Topic.get_custom_field_type("topic_field_1")).to eq(:boolean)
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
      expect(Post.get_custom_field_type("post_field_1")).to eq(:integer)
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
  
  context "category" do
    it "registers category custom fields" do
      category
      expect(Category.get_custom_field_type("category_field_1")).to eq(:json)
    end
    
    it "adds category custom fields to the basic category serializer" do
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
    it "registers group custom fields" do
      group
      expect(Group.get_custom_field_type("group_field_1")).to eq(:string)
    end
    
    it "adds group custom fields to the basic group serializer" do
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