# frozen_string_literal: true
require_relative '../../plugin_helper'

describe CustomWizard::TemplateValidator do
  fab!(:user) { Fabricate(:user) }
  let(:template) { get_wizard_fixture("wizard") }
  let(:create_category) { get_wizard_fixture("actions/create_category") }
  let(:user_condition) { get_wizard_fixture("condition/user_condition") }
  let(:permitted_json) { get_wizard_fixture("wizard/permitted") }

  it "validates valid templates" do
    expect(
      CustomWizard::TemplateValidator.new(template).perform
    ).to eq(true)
  end

  it "invalidates templates without required attributes" do
    template.delete(:id)
    expect(
      CustomWizard::TemplateValidator.new(template).perform
    ).to eq(false)
  end

  it "invalidates templates with duplicate ids if creating a new template" do
    CustomWizard::Template.save(template)
    expect(
      CustomWizard::TemplateValidator.new(template, create: true).perform
    ).to eq(false)
  end

  it "validates after time settings" do
    template[:after_time] = true
    template[:after_time_scheduled] = (Time.now + 3.hours).iso8601
    expect(
      CustomWizard::TemplateValidator.new(template).perform
    ).to eq(true)
  end

  it "invalidates invalid after time settings" do
    template[:after_time] = true
    template[:after_time_scheduled] = "not a time"
    expect(
      CustomWizard::TemplateValidator.new(template).perform
    ).to eq(false)
  end

  context "without subscription" do
    it "invalidates subscription wizard attributes" do
      template[:permitted] = permitted_json["permitted"]
      expect(
        CustomWizard::TemplateValidator.new(template).perform
      ).to eq(false)
    end

    it "invalidates subscription step attributes" do
      template[:steps][0][:condition] = user_condition['condition']
      expect(
        CustomWizard::TemplateValidator.new(template).perform
      ).to eq(false)
    end

    it "invalidates subscription field attributes" do
      template[:steps][0][:fields][0][:condition] = user_condition['condition']
      expect(
        CustomWizard::TemplateValidator.new(template).perform
      ).to eq(false)
    end

    it "invalidates subscription actions" do
      template[:actions] << create_category
      expect(
        CustomWizard::TemplateValidator.new(template).perform
      ).to eq(false)
    end
  end

  context "with standard subscription" do
    before do
      enable_subscription("standard")
    end

    it "validates wizard attributes" do
      template[:permitted] = permitted_json["permitted"]
      expect(
        CustomWizard::TemplateValidator.new(template).perform
      ).to eq(true)
    end

    it "validates step attributes" do
      template[:steps][0][:condition] = user_condition['condition']
      expect(
        CustomWizard::TemplateValidator.new(template).perform
      ).to eq(true)
    end

    it "validates field attributes" do
      template[:steps][0][:fields][0][:condition] = user_condition['condition']
      expect(
        CustomWizard::TemplateValidator.new(template).perform
      ).to eq(true)
    end
  end

  context "with business subscription" do
    before do
      enable_subscription("business")
    end

    it "validates actions" do
      template[:actions] << create_category
      expect(
        CustomWizard::TemplateValidator.new(template).perform
      ).to eq(true)
    end
  end

  context "steps" do
    CustomWizard::TemplateValidator.required[:step].each do |attribute|
      it "invalidates if \"#{attribute.to_s}\" is not present" do
        template[:steps][0][attribute] = nil
        expect(
          CustomWizard::TemplateValidator.new(template).perform
        ).to eq(false)
      end
    end
  end

  context "fields" do
    CustomWizard::TemplateValidator.required[:field].each do |attribute|
      it "invalidates if \"#{attribute.to_s}\" is not present" do
        template[:steps][0][:fields][0][attribute] = nil
        expect(
          CustomWizard::TemplateValidator.new(template).perform
        ).to eq(false)
      end
    end
  end

  context "actions" do
    CustomWizard::TemplateValidator.required[:action].each do |attribute|
      it "invalidates if \"#{attribute.to_s}\" is not present" do
        template[:actions][0][attribute] = nil
        expect(
          CustomWizard::TemplateValidator.new(template).perform
        ).to eq(false)
      end
    end
  end
end
