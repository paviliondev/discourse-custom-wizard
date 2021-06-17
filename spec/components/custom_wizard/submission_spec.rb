# frozen_string_literal: true
require_relative '../../plugin_helper'

describe CustomWizard::Submission do
  fab!(:user) { Fabricate(:user) }
  fab!(:user2) { Fabricate(:user) }

  let(:template_json) {
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
    ).read)
  }

  before do
    CustomWizard::Template.save(template_json, skip_jobs: true)

    template_json_2 = template_json.dup
    template_json_2["id"] = "super_mega_fun_wizard_2"
    CustomWizard::Template.save(template_json_2, skip_jobs: true)

    @wizard = CustomWizard::Wizard.create(template_json["id"], user)
    @wizard2 = CustomWizard::Wizard.create(template_json["id"], user2)
    @wizard3 = CustomWizard::Wizard.create(template_json_2["id"], user)

    described_class.new(@wizard, step_1_field_1: "I am a user submission").save
    described_class.new(@wizard2, step_1_field_1: "I am another user's submission").save
    described_class.new(@wizard3, step_1_field_1: "I am a user submission on another wizard").save
  end

  it "saves a user's submission" do
    expect(
      described_class.get(template_json["id"], user.id).fields["step_1_field_1"]
    ).to eq("I am a user submission")
  end

  it "list submissions by wizard" do
    expect(described_class.list(@wizard).size).to eq(2)
  end

  it "list submissions by wizard and user" do
    expect(described_class.list(@wizard, user).size).to eq(1)
  end
end