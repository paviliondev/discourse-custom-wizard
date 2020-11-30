# frozen_string_literal: true

require_relative '../../plugin_helper'

describe "custom field extensions" do
  let!(:topic) { Fabricate(:topic) }
  let!(:post) { Fabricate(:post) }
  let!(:category) { Fabricate(:category) }
  let!(:user) { Fabricate(:user) }
  let!(:group) { Fabricate(:group, users: [user]) }
  
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
  
  it "adds topic custom fields to the show topic response" do
    topic.custom_fields["topic_field_1"] = true
    topic.save_custom_fields(true)
    
    get "/t/#{topic.slug}/#{topic.id}.json"
        
    expect(response.status).to eq(200)
    expect(response.parsed_body["topic_field_1"]).to eq(true)
  end
  
  it "adds category custom fields to the show categories response" do
    category.custom_fields["category_field_1"] = { a: 1, b: 2 }
    category.save_custom_fields(true)
    
    get "/c/#{category.id}/show.json"
        
    expect(response.status).to eq(200)
    expect(response.parsed_body["category"]["category_field_1"]).to eq({ a: 1, b: 2 }.as_json)
  end
  
  it "adds group custom fields to the show group response" do
    group.custom_fields["group_field_1"] = "Group cf entry"
    group.save_custom_fields(true)
    
    sign_in(user)
    get "/groups/#{group.name}.json"

    expect(response.status).to eq(200)
    expect(response.parsed_body['group']['group_field_1']).to eq("Group cf entry")
  end
  
  it "adds post custom fields to the show post response" do
    post.custom_fields["post_field_1"] = 7
    post.save_custom_fields(true)
    
    get "/posts/#{post.id}.json"
        
    expect(response.status).to eq(200)
    expect(response.parsed_body['post_field_1']).to eq(7)
  end
  
  context "preloaded" do
    it "preloads category custom fields on site categories" do
      Site.preloaded_category_custom_fields << "other_field"
      
      category.custom_fields["category_field_1"] = { a: 1, b: 2 }
      category.save_custom_fields(true)
      
      get "/site.json"
      expect(response.status).to eq(200)
      
      site_category = response.parsed_body['categories'].select { |c| c['id'] == category.id }.first
      expect(site_category["category_field_1"]).to eq({ a: 1, b: 2 }.as_json)
    end
    
    it "preloads group custom fields on group index" do
      Group.preloaded_custom_field_names << "other_field"
      
      group = Fabricate(:group)
      group.custom_fields["group_field_1"] = "Group cf entry"
      group.save_custom_fields(true)
      
      get "/groups.json"
      expect(response.status).to eq(200)
      
      group = response.parsed_body['groups'].select { |g| g['id'] == group.id }.first
      expect(group['group_field_1']).to eq("Group cf entry")
    end
  end
end
  