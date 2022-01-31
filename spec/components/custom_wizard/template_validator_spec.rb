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

  it "only allows one after signup wizard at a time" do
    wizard_id = template[:id]
    template[:after_signup] = true
    CustomWizard::Template.save(template)

    template[:id] = "wizard_2"
    template[:after_signup] = true

    validator = CustomWizard::TemplateValidator.new(template)
    expect(validator.perform).to eq(false)
    expect(validator.errors.first.type).to eq(
      I18n.t("wizard.validation.after_signup", wizard_id: wizard_id)
    )
  end

  it "only allows a wizard with after signup to be validated twice" do
    template[:after_signup] = true
    CustomWizard::Template.save(template)
    expect(CustomWizard::TemplateValidator.new(template).perform).to eq(true)
  end

  it "only allows one after _ setting per wizard" do
    template[:after_signup] = true
    template[:after_time] = true

    validator = CustomWizard::TemplateValidator.new(template)
    expect(validator.perform).to eq(false)
    expect(validator.errors.first.type).to eq(
      I18n.t("wizard.validation.after_signup_after_time")
    )
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
