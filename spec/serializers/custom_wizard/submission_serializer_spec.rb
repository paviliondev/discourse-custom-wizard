# frozen_string_literal: true

require_relative '../../plugin_helper'

describe CustomWizard::SubmissionSerializer do
  fab!(:user1) { Fabricate(:user) }
  fab!(:user2) { Fabricate(:user) }

  let(:template_json) {
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
    ).read)
  }

  before do
    CustomWizard::Template.save(template_json, skip_jobs: true)

    wizard = CustomWizard::Wizard.create(template_json["id"], user1)
    CustomWizard::Submission.new(wizard, step_1_field_1: "I am user1 submission", submitted_at: Time.now.iso8601).save

    wizard = CustomWizard::Wizard.create(template_json["id"], user2)
    CustomWizard::Submission.new(wizard, step_1_field_1: "I am user2 submission", submitted_at: Time.now.iso8601).save
  end

  it 'should return submission attributes' do
    wizard = CustomWizard::Wizard.create(template_json["id"])
    list = CustomWizard::Submission.list(wizard, page: 0, order_by: 'id')

    json_array = ActiveModel::ArraySerializer.new(
      list.submissions,
      each_serializer: described_class
    ).as_json

    expect(json_array.length).to eq(2)
    expect(json_array[0][:id].present?).to eq(true)
    expect(json_array[0][:submitted_at].present?).to eq(true)
    expect(json_array[0][:user]).to eq(BasicUserSerializer.new(user2, root: false).as_json)
    expect(json_array[1][:user]).to eq(BasicUserSerializer.new(user1, root: false).as_json)
  end

  it "should return field values, types and labels" do
    wizard = CustomWizard::Wizard.create(template_json["id"])
    list = CustomWizard::Submission.list(wizard, page: 0, order_by: 'id')

    json_array = ActiveModel::ArraySerializer.new(
      list.submissions,
      each_serializer: described_class
    ).as_json

    expect(json_array.length).to eq(2)
    expect(json_array[0][:fields].as_json).to eq({
      "step_1_field_1": {
        "value": "I am user2 submission",
        "type": "text",
        "label": "Text"
      }
    }.as_json)
  end
end
