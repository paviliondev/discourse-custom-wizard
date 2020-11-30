# frozen_string_literal: true

require_relative '../../plugin_helper'

describe CustomWizard::LogSerializer do
  fab!(:user) { Fabricate(:user) }
  
  it 'should return log attributes' do
    CustomWizard::Log.create("First log message")
    CustomWizard::Log.create("Second log message")
    
    json_array = ActiveModel::ArraySerializer.new(
      CustomWizard::Log.list(0),
      each_serializer: CustomWizard::LogSerializer
    ).as_json 
    expect(json_array.length).to eq(2)
    expect(json_array[0][:message]).to eq("Second log message")
  end
end