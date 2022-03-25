# frozen_string_literal: true

describe CustomWizard::FieldSerializer do
  fab!(:user) { Fabricate(:user) }
  let(:template) { get_wizard_fixture("wizard") }

  before do
    CustomWizard::Template.save(template, skip_jobs: true)
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
    expect(json_array[2][:index]).to eq(2)
  end

  it "should return optional field attributes" do
    json_array = ActiveModel::ArraySerializer.new(
      @wizard.steps.second.fields,
      each_serializer: CustomWizard::FieldSerializer,
      scope: Guardian.new(user)
    ).as_json
    expect(json_array[0][:format]).to eq("YYYY-MM-DD")
    expect(json_array[5][:file_types]).to eq(".jpg,.jpeg,.png")
  end
end
