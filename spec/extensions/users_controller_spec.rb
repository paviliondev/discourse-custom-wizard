# frozen_string_literal: true

describe CustomWizardUsersController, type: :request do
  let(:template) { get_wizard_fixture("wizard") }

  before do
    @controller = UsersController.new
  end

  it "redirects a user to wizard after sign up if after signup is enabled" do
    template['after_signup'] = true
    CustomWizard::Template.save(template, skip_jobs: true)
    sign_in(Fabricate(:user))
    get "/u/account-created"
    expect(response).to redirect_to("/w/super-mega-fun-wizard")
  end
end
