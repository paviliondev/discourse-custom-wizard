# frozen_string_literal: true

require 'rails_helper'

describe CustomWizard::FieldSerializer do
  fab!(:user) { Fabricate(:user) }

  before do
    CustomWizard::Template.save(
      JSON.parse(File.open(
        "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
      ).read),
    skip_jobs: true)
    @wizard = CustomWizard::Builder.new("super_mega_fun_wizard", user).build
  end
  
  it "should return basic field attributes" do
    json_array = ActiveModel::ArraySerializer.new(
      @wizard.steps.first.fields,
      each_serializer: CustomWizard::FieldSerializer,
      scope: Guardian.new(user)
    ).as_json
    expect(json_array.length).to eq(4)
    expect(json_array[0][:label]).to eq("<p>Text</p>")
    expect(json_array[0][:description]).to eq("Text field description.")
  end
  
  it "should return optional field attributes" do
    json_array = ActiveModel::ArraySerializer.new(
      @wizard.steps.second.fields,
      each_serializer: CustomWizard::FieldSerializer,
      scope: Guardian.new(user)
    ).as_json
    expect(json_array[0][:format]).to eq("YYYY-MM-DD")
    expect(json_array[5][:file_types]).to eq(".jpg,.png")
  end
end