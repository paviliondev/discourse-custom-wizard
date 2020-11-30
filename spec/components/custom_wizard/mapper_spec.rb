require_relative '../../plugin_helper'

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
      expect(CustomWizard::Mapper.new(
        inputs: inputs['conditional_multiple_pairs'],
        data: data,
        user: user1
      ).perform).to eq(nil)
    end
  end
  
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
  
  it "interpolates user fields" do
    expect(CustomWizard::Mapper.new(
      inputs: inputs['interpolate_user_field'],
      data: data,
      user: user1
    ).perform).to eq("Name: Angus")
  end
  
  it "interpolates wizard fields" do
    expect(CustomWizard::Mapper.new(
      inputs: inputs['interpolate_wizard_field'],
      data: data,
      user: user1
    ).perform).to eq("Input 1: value 1")
  end
  
  it "interpolates date" do
    expect(CustomWizard::Mapper.new(
      inputs: inputs['interpolate_timestamp'],
      data: data,
      user: user1
    ).perform).to eq("Time: #{Time.now.strftime("%B %-d, %Y")}")
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
end