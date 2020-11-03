require 'rails_helper'

describe ExtraLocalesControllerCustomWizard, type: :request do
  before do
    CustomWizard::Template.save(
      JSON.parse(File.open(
        "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
      ).read),
    skip_jobs: true)
  end
  
  before do
    @controller = ExtraLocalesController.new
  end
  
  it "returns locales when requested by wizard" do
    expect(
      ExtraLocalesController.url("wizard")
    ).to eq(
      "#{Discourse.base_path}/extra-locales/wizard?v=#{ExtraLocalesController.bundle_js_hash("wizard")}"
    )
  end
end