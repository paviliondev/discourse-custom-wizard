# frozen_string_literal: true
module ExtraLocalesControllerCustomWizard
  private def valid_bundle?(bundle)
    super || begin
      return false unless bundle =~ /wizard/ && request.referer =~ /\/w\//
      path = URI(request.referer).path
      wizard_path = path.split('/w/').last
      wizard_id = wizard_path.split('/').first
      return true if wizard_id == "qunit"
      CustomWizard::Template.exists?(wizard_id.underscore)
    end
  end
end
