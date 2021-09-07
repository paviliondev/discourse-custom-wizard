# frozen_string_literal: true

require_relative '../../plugin_helper'

describe CustomWizard::SubmissionSerializer do
  fab!(:user) { Fabricate(:user) }

  let(:template_json) {
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
    ).read)
  }

  before do
    CustomWizard::Template.save(template_json, skip_jobs: true)
    wizard = CustomWizard::Wizard.create(template_json["id"], user)
    CustomWizard::Submission.new(wizard,
      step_1_field_1: "I am user submission",
      submitted_at: Time.now.iso8601
    ).save
    @list = CustomWizard::Submission.list(wizard, page: 0)
  end

  it 'should return submission attributes' do
    json_array = ActiveModel::ArraySerializer.new(
      @list.submissions,
      each_serializer: described_class
    ).as_json

    expect(json_array.length).to eq(1)
    expect(json_array[0][:id].present?).to eq(true)
    expect(json_array[0][:user].present?).to eq(true)
    expect(json_array[0][:submitted_at].present?).to eq(true)
  end

  it "should return field values, types and labels" do
    json_array = ActiveModel::ArraySerializer.new(
      @list.submissions,
      each_serializer: described_class
    ).as_json

    expect(json_array.length).to eq(1)
    expect(json_array[0][:fields].as_json).to eq({
      "step_1_field_1": {
        "value": "I am user submission",
        "type": "text",
        "label": "Text"
      }
    }.as_json)
  end
end
