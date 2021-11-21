# frozen_string_literal: true
require_relative '../../plugin_helper'

describe CustomWizard::TemplateValidator do
  fab!(:user) { Fabricate(:user) }

  let(:template) {
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
    ).read).with_indifferent_access
  }

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

  it "validates if no liquid syntax is in use" do
    expect(
      CustomWizard::TemplateValidator.new(template).perform
    ).to eq(true)
  end

  it "validates if liquid syntax in use is correct" do
    template[:steps][0][:description] = <<-LIQUID.strip
      {%- assign hello = "Topic Form 1" %}
    LIQUID
    expect(
      CustomWizard::TemplateValidator.new(template).perform
    ).to eq(true)
  end

  it "doesn't validate if liquid syntax in use is incorrect" do
    template[:steps][0][:description] = <<-LIQUID.strip
      {%- assign hello = "Topic Form 1" %
    LIQUID
    expect(
      CustomWizard::TemplateValidator.new(template).perform
    ).to eq(false)
  end
end
