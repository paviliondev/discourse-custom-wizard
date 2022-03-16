# frozen_string_literal: true

describe CustomWizard::LogSerializer do
  fab!(:user) { Fabricate(:user) }

  it 'should return log attributes' do
    CustomWizard::Log.create('first-test-wizard', 'perform_first_action', 'first_test_user', 'First log message')
    CustomWizard::Log.create('second-test-wizard', 'perform_second_action', 'second_test_user', 'Second log message')

    json_array = ActiveModel::ArraySerializer.new(
      CustomWizard::Log.list(0).logs,
      each_serializer: CustomWizard::LogSerializer
    ).as_json
    expect(json_array.length).to eq(2)
    expect(json_array[0][:action]).to eq("perform_second_action")
    expect(json_array[0][:username]).to eq('second_test_user')
    expect(json_array[0][:message]).to eq("Second log message")
  end
end
