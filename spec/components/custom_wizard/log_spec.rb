# frozen_string_literal: true
require_relative '../../plugin_helper'

describe CustomWizard::Log do
  before do
    CustomWizard::Log.create('first-test-wizard', 'perform_first_action', 'first_test_user', 'First log message')
    CustomWizard::Log.create('second-test-wizard', 'perform_second_action', 'second_test_user', 'Second log message')
    CustomWizard::Log.create('third-test-wizard', 'perform_third_action', 'third_test_user', 'Third log message')
  end

  it "creates logs" do
    expect(
      CustomWizard::Log.list.length
    ).to eq(3)
  end

  it "lists logs by time created" do
    expect(
      CustomWizard::Log.list.first.message
    ).to eq("Third log message")
  end

  it "paginates logs" do
    expect(
      CustomWizard::Log.list(0, 2).length
    ).to eq(2)
  end
end
