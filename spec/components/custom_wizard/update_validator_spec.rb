# frozen_string_literal: true

describe CustomWizard::UpdateValidator do
  fab!(:user)
  let(:template) { get_wizard_fixture("wizard") }
  let(:url_field) { get_wizard_fixture("field/url") }

  before do
    CustomWizard::Template.save(template, skip_jobs: true)
    @template = CustomWizard::Template.find("super_mega_fun_wizard")
  end

  def perform_validation(step_id, submission)
    wizard = CustomWizard::Builder.new(@template[:id], user).build
    updater = wizard.create_updater(step_id, submission)
    updater.validate
    updater
  end

  it "applies min length to text type fields" do
    min_length = 3

    @template[:steps][0][:fields][0][:min_length] = min_length
    @template[:steps][0][:fields][1][:min_length] = min_length

    CustomWizard::Template.save(@template)

    updater = perform_validation("step_1", step_1_field_1: "Te")
    expect(updater.errors.messages[:step_1_field_1].first).to eq(
      I18n.t("wizard.field.too_short", label: "Text", min: min_length),
    )

    updater = perform_validation("step_1", step_1_field_2: "Te")
    expect(updater.errors.messages[:step_1_field_2].first).to eq(
      I18n.t("wizard.field.too_short", label: "Textarea", min: min_length),
    )
  end

  it "prevents submission if the length is over the max length" do
    max_length = 100

    @template[:steps][0][:fields][0][:max_length] = max_length
    @template[:steps][0][:fields][1][:max_length] = max_length

    CustomWizard::Template.save(@template)
    long_string =
      "Our Competitive Capability solution offers platforms a suite of wholesale offerings. In the future, will you be able to effectively revolutionize synergies in your business? In the emerging market space, industry is ethically investing its mission critical executive searches. Key players will take ownership of their capabilities by iteratively right-sizing world-class visibilities. "
    updater = perform_validation("step_1", step_1_field_1: long_string)
    expect(updater.errors.messages[:step_1_field_1].first).to eq(
      I18n.t("wizard.field.too_long", label: "Text", max: max_length),
    )

    updater = perform_validation("step_1", step_1_field_2: long_string)
    expect(updater.errors.messages[:step_1_field_2].first).to eq(
      I18n.t("wizard.field.too_long", label: "Textarea", max: max_length),
    )
  end

  it "allows submission if the length is under or equal to the max length" do
    max_length = 100

    @template[:steps][0][:fields][0][:max_length] = max_length
    @template[:steps][0][:fields][1][:max_length] = max_length

    CustomWizard::Template.save(@template)
    hundred_chars_string =
      "This is a line, exactly hundred characters long and not more even a single character more than that."
    updater = perform_validation("step_1", step_1_field_1: hundred_chars_string)
    expect(updater.errors.messages[:step_1_field_1].first).to eq(nil)

    updater = perform_validation("step_1", step_1_field_2: hundred_chars_string)
    expect(updater.errors.messages[:step_1_field_2].first).to eq(nil)
  end

  it "applies min length only if the input is non-empty" do
    min_length = 3

    @template[:steps][0][:fields][0][:min_length] = min_length

    CustomWizard::Template.save(@template)

    updater = perform_validation("step_1", step_1_field_1: "")
    expect(updater.errors.messages[:step_1_field_1].first).to eq(nil)
  end

  it "applies max length only if the input is non-empty" do
    max_length = 100

    @template[:steps][0][:fields][0][:max_length] = max_length

    CustomWizard::Template.save(@template)
    updater = perform_validation("step_1", step_1_field_1: "")
    expect(updater.errors.messages[:step_1_field_1].first).to eq(nil)
  end

  it "standardises boolean entries" do
    updater = perform_validation("step_2", step_2_field_5: "false")
    expect(updater.submission["step_2_field_5"]).to eq(false)
  end

  it "requires required fields" do
    @template[:steps][0][:fields][1][:required] = true
    CustomWizard::Template.save(@template)

    updater = perform_validation("step_1", step_1_field_2: nil)
    expect(updater.errors.messages[:step_1_field_2].first).to eq(
      I18n.t("wizard.field.required", label: "Textarea"),
    )
  end

  context "advanced fields" do
    it "validates url fields" do
      updater = perform_validation("step_2", step_2_field_6: "https://discourse.com")
      expect(updater.errors.messages[:step_2_field_6].first).to eq(nil)
    end

    it "does not validate url fields with non-url inputs" do
      template[:steps][0][:fields] << url_field
      CustomWizard::Template.save(template)
      updater = perform_validation("step_1", step_2_field_6: "discourse")
      expect(updater.errors.messages[:step_2_field_6].first).to eq(
        I18n.t("wizard.field.not_url", label: "Url"),
      )
    end

    it "validates empty url fields" do
      updater = perform_validation("step_2", step_2_field_6: "")
      expect(updater.errors.messages[:step_2_field_6].first).to eq(nil)
    end
  end

  context "answer validation" do
    def set_answer_validation(opts)
      @template[:steps][0][:fields][0][:validations] = { answer: { status: true }.merge(opts) }
      CustomWizard::Template.save(@template)
    end

    it "blocks submission when the value does not match" do
      set_answer_validation(expected: "Paris")
      updater = perform_validation("step_1", step_1_field_1: "London")
      expect(updater.errors.messages[:step_1_field_1].first).to eq(
        I18n.t("wizard.field.answer_incorrect", label: "Text"),
      )
    end

    it "allows submission when the value matches" do
      set_answer_validation(expected: "Paris")
      updater = perform_validation("step_1", step_1_field_1: " Paris ")
      expect(updater.errors.messages[:step_1_field_1].first).to eq(nil)
    end

    it "is case sensitive by default" do
      set_answer_validation(expected: "Paris")
      updater = perform_validation("step_1", step_1_field_1: "paris")
      expect(updater.errors.messages[:step_1_field_1].first).to be_present
    end

    it "matches case insensitively when configured" do
      set_answer_validation(expected: "Paris", match: "insensitive")
      updater = perform_validation("step_1", step_1_field_1: "PARIS")
      expect(updater.errors.messages[:step_1_field_1].first).to eq(nil)
    end

    it "uses a custom message when configured" do
      set_answer_validation(expected: "Paris", message: "Nope, guess again")
      updater = perform_validation("step_1", step_1_field_1: "London")
      expect(updater.errors.messages[:step_1_field_1].first).to eq("Nope, guess again")
    end

    it "is skipped when disabled" do
      @template[:steps][0][:fields][0][:validations] = {
        answer: {
          status: false,
          expected: "Paris",
        },
      }
      CustomWizard::Template.save(@template)
      updater = perform_validation("step_1", step_1_field_1: "London")
      expect(updater.errors.messages[:step_1_field_1].first).to eq(nil)
    end

    it "defers empty values to the required check" do
      set_answer_validation(expected: "Paris")
      updater = perform_validation("step_1", step_1_field_1: "")
      expect(updater.errors.messages[:step_1_field_1].first).to eq(nil)
    end

    it "is ignored on unsupported field types" do
      @template[:steps][1][:fields][0][:validations] = {
        answer: {
          status: true,
          expected: "2021-11-13",
        },
      }
      CustomWizard::Template.save(@template)
      updater = perform_validation("step_2", step_2_field_1: "2021-11-14")
      expect(updater.errors.messages[:step_2_field_1].first).to eq(nil)
    end
  end

  it "validates date fields" do
    @template[:steps][1][:fields][0][:format] = "DD-MM-YYYY"
    CustomWizard::Template.save(@template)

    updater = perform_validation("step_2", step_2_field_1: "13-11-2021")
    expect(updater.errors.messages[:step_2_field_1].first).to eq(nil)
  end

  it 'doesn\'t validate date field if the format is not respected' do
    @template[:steps][1][:fields][0][:format] = "MM-DD-YYYY"
    CustomWizard::Template.save(@template)

    updater = perform_validation("step_2", step_2_field_1: "13-11-2021")
    expect(updater.errors.messages[:step_2_field_1].first).to eq(
      I18n.t("wizard.field.invalid_date"),
    )
  end

  it "validates date time fields" do
    @template[:steps][1][:fields][2][:format] = "DD-MM-YYYY HH:mm:ss"
    CustomWizard::Template.save(@template)

    updater = perform_validation("step_2", step_2_field_3: "13-11-2021 09:15:00")
    expect(updater.errors.messages[:step_2_field_3].first).to eq(nil)
  end

  it 'doesn\'t validate date time field if the format is not respected' do
    @template[:steps][1][:fields][2][:format] = "MM-DD-YYYY HH:mm:ss"
    CustomWizard::Template.save(@template)

    updater = perform_validation("step_2", step_2_field_3: "13-11-2021 09:15")
    expect(updater.errors.messages[:step_2_field_3].first).to eq(
      I18n.t("wizard.field.invalid_date"),
    )
  end

  describe "selection fields" do
    fab!(:category)
    fab!(:other_category, :category)
    fab!(:hidden_category) { Fabricate(:private_category, group: Fabricate(:group)) }
    fab!(:tag)
    fab!(:other_tag, :tag)
    fab!(:group) { Fabricate(:group, visibility_level: Group.visibility_levels[:public]) }
    fab!(:hidden_group) { Fabricate(:group, visibility_level: Group.visibility_levels[:owners]) }

    let(:invalid) { invalid_option("Choice") }

    before { enable_subscription("standard") }

    def set_field(attrs)
      fields = @template[:steps][0][:fields]
      fields.reject! { |field| field["id"] == "step_1_field_5" }
      fields << { id: "step_1_field_5", label: "Choice" }.merge(attrs).as_json
      expect(CustomWizard::Template.save(@template)).to be_present
    end

    def invalid_option(label)
      [I18n.t("wizard.field.invalid_option", label: label)]
    end

    def errors_for(value, step: "step_1", field: :step_1_field_5)
      perform_validation(step, field => value).errors.messages[field]
    end

    def content(output_type, output)
      [{ type: "assignment", output_type: output_type, output_connector: "set", output: output }]
    end

    it "only accepts categories the field offers" do
      set_field(type: "category", limit: 1, content: content("category", [category.id]))

      expect(errors_for([category.id])).to be_blank
      expect(errors_for([other_category.id])).to eq(invalid)
      expect(errors_for([category.id, category.id])).to eq(invalid)
    end

    it "only accepts categories the user can see" do
      set_field(type: "category")

      expect(errors_for([other_category.id])).to be_blank
      expect(errors_for([hidden_category.id])).to eq(invalid)

      set_field(type: "category", property: "slug")

      expect(errors_for([other_category.slug])).to be_blank
      expect(errors_for([hidden_category.slug])).to eq(invalid)
    end

    it "only accepts tags the field offers" do
      SiteSetting.tagging_enabled = true
      Fabricate(:tag_group, permissions: { "staff" => 1 }, tag_names: ["staff-only"])
      set_field(type: "tag", limit: 1, content: content("tag", [tag.name, other_tag.name]))

      expect(errors_for([tag.name])).to be_blank
      expect(errors_for([Fabricate(:tag).name])).to eq(invalid)
      expect(errors_for(["brand-new"])).to eq(invalid)
      expect(errors_for([tag.name, other_tag.name])).to eq(invalid)
      expect(errors_for(["#{tag.name},#{other_tag.name}"])).to eq(invalid)
      expect(errors_for([{ "name" => 5 }])).to eq(invalid)

      set_field(type: "tag", can_create_tag: true)

      expect(errors_for([other_tag.name, "brand-new"])).to be_blank
      expect(errors_for(["staff-only"])).to eq(invalid)
      expect(errors_for(["staff-only "])).to eq(invalid)
    end

    it "only accepts tags in the field's association content" do
      SiteSetting.tagging_enabled = true
      pair = { index: 0, key: tag.name, value: tag.name, connector: "association" }
      set_field(type: "tag", content: [{ type: "association", pairs: [pair] }])

      expect(errors_for([tag.name])).to be_blank
      expect(errors_for([other_tag.name])).to eq(invalid)
    end

    it "accepts tags in several tag groups" do
      SiteSetting.tagging_enabled = true
      Fabricate(:tag_group, name: "group-a", tag_names: [tag.name])
      Fabricate(:tag_group, name: "group-b", tag_names: [tag.name, other_tag.name])
      set_field(type: "tag", tag_groups: ["group-b"])

      expect(errors_for([tag.name, other_tag.name])).to be_blank
      expect(errors_for([Fabricate(:tag).name])).to eq(invalid)
    end

    it "only accepts groups the field offers" do
      set_field(type: "group")

      expect(errors_for(group.id)).to be_blank
      expect(errors_for(Group::AUTO_GROUPS[:logged_in_users])).to be_blank
      expect(errors_for(hidden_group.id)).to eq(invalid)
      expect(errors_for("0#{group.id}")).to eq(invalid)
      expect(errors_for([group.id, group.id])).to eq(invalid)

      set_field(type: "group", content: content("group", [hidden_group.id]))

      expect(errors_for(group.id)).to eq(invalid)
    end

    it "only accepts dropdown options the field offers" do
      dropdown = { step: "step_3", field: :step_3_field_1 }

      expect(errors_for("choice1", **dropdown)).to be_blank
      expect(errors_for("choice4", **dropdown)).to eq(invalid_option("Custom Dropdown"))
      expect(errors_for(%w[choice1 choice2], **dropdown)).to eq(invalid_option("Custom Dropdown"))
    end
  end
end
