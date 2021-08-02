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
      described_class.get(@wizard, user.id).fields["step_1_field_1"]
    ).to eq("I am a user submission")
  end

  it "list submissions by wizard" do
    expect(described_class.list(@wizard).size).to eq(2)
  end

  it "list submissions by wizard and user" do
    expect(described_class.list(@wizard, user_id: user.id).size).to eq(1)
  end

  context "#cleanup_incomplete_submissions" do
    it "cleans up redundant incomplete submissions on each build" do
      freeze_time Time.now + 1
      described_class.new(@wizard, step_1_field_1: "I am the second submission").save
      builder = CustomWizard::Builder.new(@wizard.id, @wizard.user)
      builder.build
      sub_list = described_class.list(@wizard, user_id: @wizard.user.id)

      expect(sub_list.length).to eq(1)
      expect(sub_list.first.fields["step_1_field_1"]).to eq("I am the second submission")
    end

    it "handles submissions without 'updated_at' field correctly" do
      described_class.new(@wizard, step_1_field_1: "I am the second submission").save
      described_class.new(@wizard, step_1_field_1: "I am the third submission").save
      sub_data = PluginStore.get("#{@wizard.id}_submissions", @wizard.user.id)
      sub_data.each do |sub|
        sub['updated_at'] = nil
      end
      PluginStore.set("#{@wizard.id}_submissions", @wizard.user.id, sub_data)
      builder = CustomWizard::Builder.new(@wizard.id, @wizard.user)
      builder.build
      sub_list = described_class.list(@wizard, user_id: @wizard.user.id)

      expect(sub_list.length).to eq(1)
      expect(sub_list.first.fields["step_1_field_1"]).to eq("I am the third submission")
    end

    it "handles submissions with and without 'updated_at' field correctly" do
      freeze_time Time.now + 1
      described_class.new(@wizard, step_1_field_1: "I am the second submission").save
      freeze_time Time.now + 2
      described_class.new(@wizard, step_1_field_1: "I am the third submission").save
      sub_data = PluginStore.get("#{@wizard.id}_submissions", @wizard.user.id)
      sub_data[0]['updated_at'] = nil
      PluginStore.set("#{@wizard.id}_submissions", @wizard.user.id, sub_data)

      builder = CustomWizard::Builder.new(@wizard.id, @wizard.user)
      builder.build
      sub_list = described_class.list(@wizard, user_id: @wizard.user.id)

      expect(sub_list.length).to eq(1)
      expect(sub_list.first.fields["step_1_field_1"]).to eq("I am the third submission")
    end
  end
end
