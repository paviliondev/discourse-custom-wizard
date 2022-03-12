# frozen_string_literal: true

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

  let(:liquid_syntax_error) {
    "Liquid syntax error: Tag '{%' was not properly terminated with regexp: /\\%\\}/"
  }

  def expect_validation_success
    expect(
      CustomWizard::TemplateValidator.new(template).perform
    ).to eq(true)
  end

  def expect_validation_failure(object_id, message)
    validator = CustomWizard::TemplateValidator.new(template)
    expect(validator.perform).to eq(false)
    expect(validator.errors.first.message).to eq("Liquid syntax error in #{object_id}: #{message}")
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
      expect_validation_failure("step_1.raw_description", liquid_syntax_error)
    end

    context "validation targets" do
      context "fields" do
        it "validates descriptions" do
          template[:steps][0][:fields][0][:description] = invalid_liquid_template
          expect_validation_failure("step_1_field_1.description", liquid_syntax_error)
        end

        it "validates placeholders" do
          template[:steps][0][:fields][0][:placeholder] = invalid_liquid_template
          expect_validation_failure("step_1_field_1.placeholder", liquid_syntax_error)
        end

        it "validates preview templates" do
          template[:steps][0][:fields][4][:preview_template] = invalid_liquid_template
          expect_validation_failure("step_1_field_5.preview_template", liquid_syntax_error)
        end
      end

      context "steps" do
        it "validates descriptions" do
          template[:steps][0][:raw_description] = invalid_liquid_template
          expect_validation_failure("step_1.raw_description", liquid_syntax_error)
        end
      end

      context "actions" do
        it "validates post builder" do
          action = nil
          action_index = nil

          template[:actions].each_with_index do |a, i|
            if a["post_builder"]
              action = a
              action_index = i
              break
            end
          end
          template[:actions][action_index][:post_template] = invalid_liquid_template

          expect_validation_failure("#{action[:id]}.post_template", liquid_syntax_error)
        end
      end
    end
  end
end
