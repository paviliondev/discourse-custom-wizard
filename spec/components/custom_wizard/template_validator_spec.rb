# frozen_string_literal: true
require_relative '../../plugin_helper'

describe CustomWizard::TemplateValidator do
  fab!(:user) { Fabricate(:user) }
  let(:template) { get_wizard_fixture("wizard") }
  let(:create_category) { get_wizard_fixture("actions/create_category") }
  let(:user_condition) { get_wizard_fixture("condition/user_condition") }

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

  it "invalidates pro step attributes without a pro subscription" do
    template[:steps][0][:condition] = user_condition['condition']
    expect(
      CustomWizard::TemplateValidator.new(template).perform
    ).to eq(false)
  end

  it "invalidates pro field attributes without a pro subscription" do
    template[:steps][0][:fields][0][:condition] = user_condition['condition']
    expect(
      CustomWizard::TemplateValidator.new(template).perform
    ).to eq(false)
  end

  it "invalidates pro actions without a pro subscription" do
    template[:actions] << create_category
    expect(
      CustomWizard::TemplateValidator.new(template).perform
    ).to eq(false)
  end

  context "with pro subscription" do
    before do
      enable_pro
    end

    it "validates pro step attributes" do
      template[:steps][0][:condition] = user_condition['condition']
      expect(
        CustomWizard::TemplateValidator.new(template).perform
      ).to eq(true)
    end

    it "validates pro field attributes" do
      template[:steps][0][:fields][0][:condition] = user_condition['condition']
      expect(
        CustomWizard::TemplateValidator.new(template).perform
      ).to eq(true)
    end

    it "validates pro actions" do
      template[:actions] << create_category
      expect(
        CustomWizard::TemplateValidator.new(template).perform
      ).to eq(true)
    end
  end
end
