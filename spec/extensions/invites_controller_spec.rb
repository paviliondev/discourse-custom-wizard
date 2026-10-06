# frozen_string_literal: true

describe InvitesControllerCustomWizard, type: :request do
  fab!(:topic)
  let(:invite) { Invite.generate(topic.user, email: "angus@mcleod.org", topic: topic) }
  let(:template) { get_wizard_fixture("wizard") }

  before { SiteSetting.enable_local_logins_via_code = false }

  it "redirects a user to wizard after invite if after signup is enabled" do
    template["after_signup"] = true
    CustomWizard::Template.save(template, skip_jobs: true)
    put "/invites/show/#{invite.invite_key}.json"
    expect(response.status).to eq(200)
    expect(cookies[:destination_url]).to eq("/w/super-mega-fun-wizard")
  end

  it "redirects an activated invitee to the wizard in the JSON response" do
    template["after_signup"] = true
    CustomWizard::Template.save(template, skip_jobs: true)

    put "/invites/show/#{invite.invite_key}.json", params: { email_token: invite.email_token }

    expect(response.status).to eq(200)
    expect(response.parsed_body["redirect_to"]).to eq("/w/super-mega-fun-wizard")
  end
end
