require_relative '../plugin_helper'

describe CustomWizardStepExtension do
  let(:step_hash) do
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/step/step.json"
    ).read).with_indifferent_access
  end
  
  it "adds custom step attributes" do
    step = Wizard::Step.new(step_hash[:id])    
    [
      :title,
      :description,
      :key,
      :permitted,
      :permitted_message
    ].each do |attr|
      step.send("#{attr.to_s}=", step_hash[attr])
      expect(step.send(attr)).to eq(step_hash[attr])
    end
  end    
end