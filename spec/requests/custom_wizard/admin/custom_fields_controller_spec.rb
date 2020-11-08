require 'rails_helper'

describe CustomWizard::AdminCustomFieldsController do
  fab!(:admin_user) { Fabricate(:user, admin: true) }
  
  let(:custom_field_json) {
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/custom_field/custom_fields.json"
    ).read)
  }
  
  before do
    custom_field_json['custom_fields'].each do |field_json|
      CustomWizard::CustomField.new(nil, field_json).save
    end
    sign_in(admin_user)
  end

  it "returns the list of custom fields" do
    get "/admin/wizards/custom-fields.json"
    expect(response.parsed_body.length).to eq(4)
  end
  
  it "updates the list of custom fields" do
    custom_field_json['custom_fields'][0]['type'] = 'string'
    put "/admin/wizards/custom-fields.json", params: custom_field_json
    expect(response.status).to eq(200)
    expect(
      CustomWizard::CustomField.find('topic_field_1').type
    ).to eq('string')
  end
end