module ExtraLocalesControllerCustomWizard
  private def valid_bundle?(bundle)
    super || begin
      return false unless bundle =~ /wizard/ && request.referer =~ /\/w\//
      path = URI(request.referer).path
      wizard_id = path.split('/w/').last
      CustomWizard::Template.exists?(wizard_id.underscore)
    end
  end
end
