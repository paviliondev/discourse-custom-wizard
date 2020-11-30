require_relative '../plugin_helper'

describe ExtraLocalesControllerCustomWizard, type: :request do
  let(:new_user) { Fabricate(:user, trust_level: TrustLevel[0]) }
  let(:staff_user) { Fabricate(:moderator) }
  
  let(:template) {
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
    ).read)
  }
  
  let(:permitted) {
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard/permitted.json"
    ).read)
  }
  
  before do
    CustomWizard::Template.save(template, skip_jobs: true)
  end
  
  before do
    js_hash = ExtraLocalesController.bundle_js_hash("wizard")
    @locale_url = "#{Discourse.base_path}/extra-locales/wizard?v=#{js_hash}"
  end
  
  it "generates the correct wizard locale url" do
    expect(ExtraLocalesController.url("wizard")).to eq(@locale_url)
  end
  
  it "returns wizard locales when requested by user in wizard" do
    sign_in(new_user)
    
    get @locale_url, headers: { 'REFERER' => "/w/super-mega-fun-wizard" }
    expect(response.status).to eq(200)
  end
  
  it "doesnt return wizard locales if user cant access wizard" do
    template[:permitted] = permitted["permitted"]
    CustomWizard::Template.save(template.as_json)
    
    sign_in(new_user)
    get @locale_url, headers: { 'REFERER' => "/w/super-mega-fun-wizard" }
    expect(response.status).to eq(403)
  end
  
  it "doesnt return wizard locales to non-staff when requested outside of wizard" do
    sign_in(new_user)
    get @locale_url
    expect(response.status).to eq(403)
  end
  
  it "returns wizard locales to staff when requested outside of wizard" do
    sign_in(staff_user)
    get @locale_url
    expect(response.status).to eq(200)
  end
end