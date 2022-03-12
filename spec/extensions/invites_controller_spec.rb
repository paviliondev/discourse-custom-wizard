# frozen_string_literal: true

describe InvitesControllerCustomWizard, type: :request do
  fab!(:topic) { Fabricate(:topic) }
  let(:invite) { Invite.generate(topic.user, email: "angus@mcleod.org", topic: topic) }

  let(:template) do
    JSON.parse(File.open(
      "#{Rails.root}/plugins/discourse-custom-wizard/spec/fixtures/wizard.json"
    ).read)
  end

  before do
    @controller = InvitesController.new
  end

  it "redirects a user to wizard after invite if after signup is enabled" do
    template['after_signup'] = true
    CustomWizard::Template.save(template, skip_jobs: true)
    put "/invites/show/#{invite.invite_key}.json"
    expect(cookies[:destination_url]).to eq("/w/super-mega-fun-wizard")
  end
end
