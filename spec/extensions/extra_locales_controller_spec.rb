# frozen_string_literal: true

describe ExtraLocalesControllerCustomWizard, type: :request do
  let(:new_user) { Fabricate(:user, trust_level: TrustLevel[0]) }
  let(:staff_user) { Fabricate(:moderator) }
  let(:template) { get_wizard_fixture("wizard") }
  let(:permitted) { get_wizard_fixture("wizard/permitted") }

  before { CustomWizard::Template.save(template, skip_jobs: true) }

  before do
    js_hash = ExtraLocalesController.bundle_js_hash("wizard")
    @locale_url = "#{Discourse.base_path}/extra-locales/wizard?v=#{js_hash}"
  end

  it "generates the correct wizard locale url" do
    expect(ExtraLocalesController.url("wizard")).to eq(@locale_url)
  end

  it "returns wizard locales when requested by user in wizard" do
    sign_in(new_user)

    get @locale_url, headers: { "REFERER" => "/w/super-mega-fun-wizard" }
    expect(response.status).to eq(200)
  end

  it "returns wizard locales when requested by user in a wizard step" do
    sign_in(new_user)

    get @locale_url, headers: { "REFERER" => "/w/super-mega-fun-wizard/steps/step_1" }
    expect(response.status).to eq(200)
  end

  it "return wizard locales if user cant access wizard" do
    template[:permitted] = permitted["permitted"]
    CustomWizard::Template.save(template.as_json)

    sign_in(new_user)
    get @locale_url, headers: { "REFERER" => "/w/super-mega-fun-wizard" }
    expect(response.status).to eq(200)
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
