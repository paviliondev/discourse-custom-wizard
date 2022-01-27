# frozen_string_literal: true
require_relative '../../plugin_helper'

describe CustomWizard::TemplateValidator do
  fab!(:user) { Fabricate(:user) }

  let(:template) {
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
    ).read).with_indifferent_access
  }
  let(:valid_liquid_template) {
    <<-LIQUID.strip
        {%- assign hello = "Topic Form 1" %}
    LIQUID
  }

  let(:invalid_liquid_template) {
    <<-LIQUID.strip
        {%- assign hello = "Topic Form 1" %
      LIQUID
  }

  def expect_validation_success
    expect(
      CustomWizard::TemplateValidator.new(template).perform
    ).to eq(true)
  end

  def expect_validation_failure
    expect(
      CustomWizard::TemplateValidator.new(template).perform
    ).to eq(false)
  end

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

  context "liquid templates" do
    it "validates if no liquid syntax in use" do
      expect_validation_success
    end

    it "validates if liquid syntax in use is correct" do
      template[:steps][0][:raw_description] = valid_liquid_template
      expect_validation_success
    end

    it "doesn't validate if liquid syntax in use is incorrect" do
      template[:steps][0][:raw_description] = invalid_liquid_template
      expect_validation_failure
    end

    context "validation targets" do
      context "fields" do
        it "validates descriptions" do
          template[:steps][0][:fields][0][:description] = invalid_liquid_template
          expect_validation_failure
        end

        it "validates preview templates" do
          template[:steps][0][:fields][4][:preview_template] = invalid_liquid_template
          expect_validation_failure
        end

        it "validates placeholders" do
          template[:steps][0][:fields][0][:description] = invalid_liquid_template
          expect_validation_failure
        end
      end

      context "steps" do
        it "validates descriptions" do
          template[:steps][0][:raw_description] = invalid_liquid_template
          expect_validation_failure
        end
      end

      context "actions" do
        it "validates post builder" do
          action_index = template[:actions].index { |action| action[:post_builder] }
          template[:actions][action_index][:post_template] = invalid_liquid_template

          expect_validation_failure
        end
      end
    end
  end
end
