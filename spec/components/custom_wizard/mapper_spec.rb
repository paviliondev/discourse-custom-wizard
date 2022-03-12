# frozen_string_literal: true

describe CustomWizard::Mapper do
  fab!(:user1) {
    Fabricate(:user,
      name: "Angus",
      username: "angus",
      email: "angus@email.com",
      trust_level: TrustLevel[3]
    )
  }
  fab!(:user2) {
    Fabricate(:user,
      name: "Patrick",
      username: "patrick",
      email: "patrick@email2.com",
      trust_level: TrustLevel[1]
    )
  }
  fab!(:user_field) {
    field = Fabricate(:user_field,
      id: 3,
      name: 'dropdown_field',
      description: 'field desc',
      field_type: 'dropdown',
      user_field_options_attributes: [
        { value: "a" },
        { value: "b" },
        { value: "c" }
      ]
    )
  }
  let(:inputs) {
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/mapper/inputs.json"
    ).read)
  }
  let(:data) {
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/mapper/data.json"
    ).read)
  }
  let(:template_params) {
    {
      "step_1_field_1" => "Hello"
    }
  }
  let(:template_params_empty) {
    {
      "step_1_field_1" => nil,
      "step_1_field_2" => nil,
      "step_1_field_3" => ""
    }
  }
  let(:template_params_non_empty) {
    {
      "step_1_field_1" => nil,
      "step_1_field_2" => "",
      "step_1_field_3" => "Value"
    }
  }
  let(:template_params_multiple_non_empty) {
    {
      "step_1_field_1" => nil,
      "step_1_field_2" => "Value1",
      "step_1_field_3" => "Value"
    }
  }

  def create_template_mapper(data, user)
    CustomWizard::Mapper.new(
      data: data,
      user: user
    )
  end

  it "maps values" do
    expect(CustomWizard::Mapper.new(
      inputs: inputs['assignment'],
      data: data,
      user: user1
    ).perform).to eq([13])
  end

  it "maps associations" do
    association = CustomWizard::Mapper.new(
      inputs: inputs['association'],
      data: data,
      user: user1
    ).perform
    expect(association.length).to eq(3)
    expect(association.first[:value]).to eq("Choice 1")
  end

  context "conditional mapping" do
    it "maps when the condition is met" do
      expect(CustomWizard::Mapper.new(
        inputs: inputs['conditional'],
        data: data,
        user: user1
      ).perform).to eq("true")
    end

    it "does not map when the condition is not met" do
      expect(CustomWizard::Mapper.new(
        inputs: inputs['conditional'],
        data: data,
        user: user2
      ).perform).to eq(nil)
    end

    it "maps when multiple conditions are met" do
      expect(CustomWizard::Mapper.new(
        inputs: inputs['conditional_multiple_pairs'],
        data: data,
        user: user1
      ).perform).to eq("true")
    end

    it "does not map when one of multiple conditions are not met" do
      user1.email = "angus@other-email.com"
      user1.save

      expect(CustomWizard::Mapper.new(
        inputs: inputs['conditional_multiple_pairs'],
        data: data,
        user: user1
      ).perform).to eq(nil)
    end
  end

  context "conditional validation" do
    it "validates valid data" do
      expect(CustomWizard::Mapper.new(
        inputs: inputs['validation'],
        data: data,
        user: user1
      ).perform).to eq(true)
    end

    it "does not validate invalid data" do
      data["input_2"] = "value 3"
      expect(CustomWizard::Mapper.new(
        inputs: inputs['validation'],
        data: data,
        user: user1
      ).perform).to eq(false)
    end

    context "using or condition" do
      it "validates the data when all of the conditions are met" do
        expect(CustomWizard::Mapper.new(
          inputs: inputs['validation_multiple_pairs'],
          data: data,
          user: user1,
          opts: {
            multiple: true
          }
        ).perform.any?).to eq(true)
      end

      it "validates the data when one of the conditions are met" do
        custom_data = data.dup
        custom_data['input_1'] = 'value 3'
        expect(CustomWizard::Mapper.new(
          inputs: inputs['validation_multiple_pairs'],
          data: custom_data,
          user: user1,
          opts: {
            multiple: true
          }
        ).perform.any?).to eq(true)
      end

      it "doesn't validate the data when none of the conditions are met" do
        custom_data = data.dup
        custom_data['input_1'] = 'value 3'
        custom_data['input_2'] = 'value 4'
        expect(CustomWizard::Mapper.new(
          inputs: inputs['validation_multiple_pairs'],
          data: custom_data,
          user: user1,
          opts: {
            multiple: true
          }
        ).perform.any?).to eq(false)
      end
    end
  end

  it "maps text fields" do
    expect(CustomWizard::Mapper.new(
      inputs: inputs['assignment_text'],
      data: data,
      user: user1
    ).perform).to eq("Value")
  end

  it "maps user fields" do
    expect(CustomWizard::Mapper.new(
      inputs: inputs['assignment_user_field'],
      data: data,
      user: user1
    ).perform).to eq("Angus")
  end

  it "maps user field options" do
    expect(CustomWizard::Mapper.new(
      inputs: inputs['assignment_user_field_options'],
      data: data,
      user: user1
    ).perform).to eq(["a", "b", "c"])
  end

  it "maps wizard fields" do
    expect(CustomWizard::Mapper.new(
      inputs: inputs['assignment_wizard_field'],
      data: data,
      user: user1
    ).perform).to eq("value 1")
  end

  it "maps wizard actions" do
    expect(CustomWizard::Mapper.new(
      inputs: inputs['assignment_wizard_action'],
      data: data,
      user: user1
    ).perform).to eq("value 2")
  end

  context "interpolates" do
    it "user fields" do
      expect(CustomWizard::Mapper.new(
        inputs: inputs['interpolate_user_field'],
        data: data,
        user: user1
      ).perform).to eq("Name: Angus")
    end

    it "user emails" do
      expect(CustomWizard::Mapper.new(
        inputs: inputs['interpolate_user_email'],
        data: data,
        user: user1
      ).perform).to eq("Email: angus@email.com")
    end

    it "user options" do
      user1.user_option.update_columns(email_level: UserOption.email_level_types[:never])

      expect(CustomWizard::Mapper.new(
        inputs: inputs['interpolate_user_option'],
        data: data,
        user: user1
      ).perform).to eq("Email Level: #{UserOption.email_level_types[:never]}")
    end

    it "date" do
      expect(CustomWizard::Mapper.new(
        inputs: inputs['interpolate_timestamp'],
        data: data,
        user: user1
      ).perform).to eq("Time: #{Time.now.strftime("%B %-d, %Y")}")
    end
  end

  it "handles greater than pairs" do
    expect(CustomWizard::Mapper.new(
      inputs: inputs['greater_than_pair'],
      data: data,
      user: user1
    ).perform).to eq(true)
    expect(CustomWizard::Mapper.new(
      inputs: inputs['greater_than_pair'],
      data: data,
      user: user2
    ).perform).to eq(false)
  end

  it "handles less than pairs" do
    expect(CustomWizard::Mapper.new(
      inputs: inputs['less_than_pair'],
      data: data,
      user: user1
    ).perform).to eq(false)
    expect(CustomWizard::Mapper.new(
      inputs: inputs['less_than_pair'],
      data: data,
      user: user2
    ).perform).to eq(true)
  end

  it "handles greater than or equal pairs" do
    expect(CustomWizard::Mapper.new(
      inputs: inputs['greater_than_or_equal_pair'],
      data: data,
      user: user1
    ).perform).to eq(true)
    expect(CustomWizard::Mapper.new(
      inputs: inputs['greater_than_or_equal_pair'],
      data: data,
      user: user2
    ).perform).to eq(true)
  end

  it "handles less than or equal pairs" do
    expect(CustomWizard::Mapper.new(
      inputs: inputs['less_than_or_equal_pair'],
      data: data,
      user: user1
    ).perform).to eq(true)
    expect(CustomWizard::Mapper.new(
      inputs: inputs['less_than_or_equal_pair'],
      data: data,
      user: user2
    ).perform).to eq(true)
  end

  it "handles regex pairs" do
    expect(CustomWizard::Mapper.new(
      inputs: inputs['regex_pair'],
      data: data,
      user: user1
    ).perform).to eq(true)
    expect(CustomWizard::Mapper.new(
      inputs: inputs['regex_pair'],
      data: data,
      user: user2
    ).perform).to eq(false)
  end

  it "handles shorthand pairs" do
    expect(CustomWizard::Mapper.new(
      inputs: inputs['shorthand_pair'],
      data: data,
      user: user1
    ).perform).to eq(false)
  end

  context "output templating" do
    it "passes the correct values to the template" do
      template = "w{step_1_field_1}"
      mapper = create_template_mapper(template_params, user1)
      result = mapper.interpolate(
        template.dup,
        template: true,
        user: true,
        wizard: true,
        value: true
      )
      expect(result).to eq(template_params["step_1_field_1"])
    end

    it "treats replaced values as string literals" do
      template = '{{ "w{step_1_field_1}" | size }}'
      mapper = create_template_mapper(template_params, user1)
      result = mapper.interpolate(
        template.dup,
        template: true,
        user: true,
        wizard: true,
        value: true
      )
      expect(result).to eq(template_params["step_1_field_1"].size.to_s)
    end

    it "allows the wizard values to be used inside conditionals" do
      template = <<-LIQUID
        {%- if "w{step_1_field_1}" contains "ello" -%}
          Correct
        {%- else -%}
          Incorrect
        {%-endif-%}
      LIQUID
      mapper = create_template_mapper(template_params, user1)
      result = mapper.interpolate(
        template.dup,
        template: true,
        user: true,
        wizard: true,
        value: true
      )
      expect(result).to eq("Correct")
    end

    it "can access data passed to render method as variable" do
      template = "{{step_1_field_1.size}}"
      mapper = create_template_mapper(template_params, user1)
      result = mapper.interpolate(
        template.dup,
        template: true,
        user: true,
        wizard: true,
        value: true
      )
      expect(result).to eq(template_params["step_1_field_1"].size.to_s)
    end

    it "doesn't parse the template when template param is false" do
      template = <<-LIQUID.strip
        {{ "w{step_1_field_1}" | size}}
      LIQUID
      mapper = create_template_mapper(template_params, user1)
      result = mapper.interpolate(
        template.dup,
        template: false,
      )
      expect(result).to eq(template)
    end

    context "custom filter: 'first_non_empty'" do
      it "gives first non empty element from list" do
        template = <<-LIQUID.strip
          {%- assign entry = "" | first_non_empty: step_1_field_1, step_1_field_2, step_1_field_3 -%}
          {{ entry }}
        LIQUID
        mapper = create_template_mapper(template_params_non_empty, user1)
        result = mapper.interpolate(
          template.dup,
          template: true,
          user: true,
          wizard: true,
          value: true
        )
        expect(result).to eq(template_params_non_empty["step_1_field_3"])
      end

      it "gives first non empty element from list when multiple non empty values present" do
        template = <<-LIQUID.strip
          {%- assign entry = "" | first_non_empty: step_1_field_1, step_1_field_2, step_1_field_3 -%}
          {{ entry }}
        LIQUID
        mapper = create_template_mapper(template_params_multiple_non_empty, user1)
        result = mapper.interpolate(
          template.dup,
          template: true,
          user: true,
          wizard: true,
          value: true
        )
        expect(result).to eq(template_params_multiple_non_empty["step_1_field_2"])
      end

      it "gives empty if all elements are empty" do
        template = <<-LIQUID.strip
          {%- assign entry = "" | first_non_empty: step_1_field_1, step_1_field_2, step_1_field_3 -%}
          {%- if entry -%}
            {{ entry }}
          {%- endif -%}
        LIQUID
        mapper = create_template_mapper(template_params_empty, user1)
        result = mapper.interpolate(
          template.dup,
          template: true,
          user: true,
          wizard: true,
          value: true
        )
        expect(result).to eq("")
      end
    end
  end
end
