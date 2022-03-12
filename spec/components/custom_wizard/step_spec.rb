# frozen_string_literal: true

describe CustomWizard::Step do
  let(:step_hash) do
    JSON.parse(
      File.open(
        "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/step/step.json"
      ).read
    ).with_indifferent_access
  end

  let(:field_hash) do
    JSON.parse(
      File.open(
        "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/field/field.json"
      ).read
    ).with_indifferent_access
  end

  before do
    @step = CustomWizard::Step.new(step_hash[:id])
  end

  it "adds fields" do
    @step.add_field(field_hash)
    expect(@step.fields.size).to eq(1)
    expect(@step.fields.first.index).to eq(0)
  end

  it "adds fields with custom indexes" do
    field_hash[:index] = 2
    @step.add_field(field_hash)
    expect(@step.fields.first.index).to eq(2)
  end
end
