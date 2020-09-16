module CustomWizardUsersController
  def account_created
    if current_user.present? &&
        (wizard = CustomWizard::Wizard.after_signup(current_user))
      return redirect_to "/w/#{wizard.id.dasherize}"
    end
    super
  end
end