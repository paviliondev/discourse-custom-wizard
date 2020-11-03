require 'rails_helper'

describe CustomWizard::Field do
  before do 
    CustomWizard::Field.register(
      'location',
      'discourse-locations',
      ['components', 'helpers', 'lib', 'stylesheets', 'templates'],
      type_opts: {
        prefill: { "coordinates": [35.3082, 149.1244] }
      }
    )
  end
  
  it "registers custom field types" do  
    expect(CustomWizard::Field.types[:location].present?).to eq(true)
  end
  
  it "allows custom field types to set default attributes" do
    expect(
      CustomWizard::Field.types[:location][:prefill]
    ).to eq({ "coordinates": [35.3082, 149.1244] })
  end
  
  it "registers custom field assets" do
    expect(
      CustomWizard::Field.require_assets['discourse-locations']
    ).to eq(['components', 'helpers', 'lib', 'stylesheets', 'templates'])
  end
end