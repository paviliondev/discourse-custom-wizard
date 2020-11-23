module ExtraLocalesControllerCustomWizard
  private def valid_bundle?(bundle)
    super || begin
      return false unless bundle =~ /wizard/ && request.referer =~ /\/w\//
      path = URI(request.referer).path
      wizard_id = path.split('/w/').last
      wizard = CustomWizard::Wizard.create(wizard_id.underscore, current_user)
      wizard && wizard.can_access?
    end
  end
end