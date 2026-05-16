# frozen_string_literal: true

describe CustomWizard::FieldSerializer do
  fab!(:user)
  let(:template) { get_wizard_fixture("wizard") }

  before do
    CustomWizard::Template.save(template, skip_jobs: true)
    @wizard = CustomWizard::Builder.new("super_mega_fun_wizard", user).build
  end

  it "should return basic field attributes" do
    json_array =
      ActiveModel::ArraySerializer.new(
        @wizard.steps.first.fields,
        each_serializer: CustomWizard::FieldSerializer,
        scope: Guardian.new(user),
      ).as_json

    expect(json_array.size).to eq(@wizard.steps.first.fields.size)
    expect(json_array[0][:label]).to eq("<p>Text</p>")
    expect(json_array[0][:description]).to eq("Text field description.")
    expect(json_array[2][:index]).to eq(2)
  end

  it "never exposes server-only answer validation to the client" do
    template[:steps][0][:fields][0][:validations] = {
      answer: {
        status: true,
        expected: "Paris",
        message: "secret",
      },
    }
    template[:steps][0][:fields][1][:validations] = {
      similar_topics: {
        status: true,
        position: "below",
      },
    }
    CustomWizard::Template.save(template)
    wizard = CustomWizard::Builder.new("super_mega_fun_wizard", user).build

    json_array =
      ActiveModel::ArraySerializer.new(
        wizard.steps.first.fields,
        each_serializer: CustomWizard::FieldSerializer,
        scope: Guardian.new(user),
      ).as_json

    expect(json_array[0][:validations]).to eq({})
    expect(json_array[1][:validations]["below"]).to have_key("similar_topics")
  end

  it "should return optional field attributes" do
    json_array =
      ActiveModel::ArraySerializer.new(
        @wizard.steps.second.fields,
        each_serializer: CustomWizard::FieldSerializer,
        scope: Guardian.new(user),
      ).as_json
    expect(json_array[0][:format]).to eq("YYYY-MM-DD")
  end
end
