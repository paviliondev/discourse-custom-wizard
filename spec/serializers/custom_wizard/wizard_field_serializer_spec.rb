# frozen_string_literal: true

describe CustomWizard::FieldSerializer do
  fab!(:user) { Fabricate(:user) }

  before do
    CustomWizard::Template.save(
      JSON.parse(File.open(
        "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
      ).read),
    skip_jobs: true)
    @wizard = CustomWizard::Builder.new("super_mega_fun_wizard", user).build
  end

  it "should return basic field attributes" do
    json_array = ActiveModel::ArraySerializer.new(
      @wizard.steps.first.fields,
      each_serializer: CustomWizard::FieldSerializer,
      scope: Guardian.new(user)
    ).as_json

    expect(json_array.size).to eq(@wizard.steps.first.fields.size)
    expect(json_array[0][:label]).to eq("<p>Text</p>")
    expect(json_array[0][:description]).to eq("Text field description.")
    expect(json_array[3][:index]).to eq(3)
  end

  it "should return optional field attributes" do
    json_array = ActiveModel::ArraySerializer.new(
      @wizard.steps.second.fields,
      each_serializer: CustomWizard::FieldSerializer,
      scope: Guardian.new(user)
    ).as_json
    expect(json_array[0][:format]).to eq("YYYY-MM-DD")
    expect(json_array[6][:file_types]).to eq(".jpg,.jpeg,.png")
  end
end
