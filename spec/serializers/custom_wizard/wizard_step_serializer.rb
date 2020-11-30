# frozen_string_literal: true

require_relative '../../plugin_helper'

describe CustomWizard::StepSerializer do
  fab!(:user) { Fabricate(:user) }
  
  let(:required_data_json) {
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/step/required_data.json"
    ).read)
  }
  
  before do
    CustomWizard::Template.save(
      JSON.parse(File.open(
        "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
      ).read),
    skip_jobs: true)
    @wizard = CustomWizard::Builder.new("super_mega_fun_wizard", user).build
  end
  
  it 'should return basic step attributes' do
    json_array = ActiveModel::ArraySerializer.new(
      @wizard.steps,
      each_serializer: CustomWizard::StepSerializer,
      scope: Guardian.new(user)
    ).as_json
    expect(json_array[0][:wizard_step][:title]).to eq("Text")
    expect(json_array[0][:wizard_step][:description]).to eq("Text inputs!")
  end
  
  it 'should return fields' do
    json_array = ActiveModel::ArraySerializer.new(
      @wizard.steps,
      each_serializer: CustomWizard::StepSerializer,
      scope: Guardian.new(user)
    ).as_json
    expect(json_array[0][:wizard_step][:fields].length).to eq(4)
  end
  
  context 'with required data' do
    before do
      @template[:steps][0][:required_data] = required_data_json['required_data']
      @template[:steps][0][:required_data_message] = required_data_json['required_data_message']
      CustomWizard::Template.save(@template.as_json)
    end
    
    it 'should return permitted attributes' do
      json_array = ActiveModel::ArraySerializer.new(
        @wizard.steps,
        each_serializer: CustomWizard::StepSerializer,
        scope: Guardian.new(user)
      ).as_json
      expect(json_array[0][:wizard_step][:permitted]).to eq(false)
      expect(json_array[0][:wizard_step][:permitted_message]).to eq("Missing required data")
    end
  end
end