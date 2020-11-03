require 'rails_helper'

describe CustomWizardFieldExtension do
  let(:field_hash) do
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/field/field.json"
    ).read).with_indifferent_access
  end
  
  it "adds custom field attributes" do
    field = Wizard::Field.new(field_hash)
    expect(field.id).to eq("field_id")
    expect(field.label).to eq("<p>Field Label</p>")
    expect(field.image).to eq("field_image_url.png")
    expect(field.description).to eq("Field description")
    expect(field.required).to eq(true)
    expect(field.key).to eq("field.locale.key")
    expect(field.type).to eq("field_type")
    expect(field.content).to eq([])
  end    
end