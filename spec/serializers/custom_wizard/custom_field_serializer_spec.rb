# frozen_string_literal: true

require_relative '../../plugin_helper'

describe CustomWizard::CustomFieldSerializer do
  fab!(:user) { Fabricate(:user) }
  
  let(:custom_field_json) {
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/custom_field/custom_fields.json"
    ).read)
  }
  
  it 'should return custom field attributes' do
    custom_field_json['custom_fields'].each do |field_json|
      CustomWizard::CustomField.new(nil, field_json).save
    end
    
    json = CustomWizard::CustomFieldSerializer.new(
      CustomWizard::CustomField.find_by_name("topic_field_1"),
      scope: Guardian.new(user),
      root: false
    ).as_json
    expect(json[:name]).to eq("topic_field_1")
    expect(json[:klass]).to eq("topic")
    expect(json[:type]).to eq("boolean")
    expect(json[:serializers]).to match_array(["topic_list_item","topic_view"])
  end
end