module InvitesControllerCustomWizard
  def path(url)
    if ::Wizard.user_requires_completion?(@user)
      wizard_id = @user.custom_fields['redirect_to_wizard']

      if wizard_id && url != '/'
        CustomWizard::Wizard.set_submission_redirect(@user, wizard_id, url)
        url = "/w/#{wizard_id.dasherize}"
      end
    end
    super
  end

  private def post_process_invite(user)
    super
    @user = user
  end
end