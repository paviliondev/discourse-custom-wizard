require 'rails_helper'

describe CustomWizard::Log do
  before do
    CustomWizard::Log.create("First log message")
    CustomWizard::Log.create("Second log message")
    CustomWizard::Log.create("Third log message")
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