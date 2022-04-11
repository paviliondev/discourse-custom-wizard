# frozen_string_literal: true

module CustomWizardContentSecurityPolicyExtension
  def path_specific_extension(path_info)
    super.tap do |obj|
      for_wizard_qunit_route = !Rails.env.production? && ["/w/qunit"].include?(path_info)
      puts "PATH INFO: #{path_info}"
      puts "FOR WIZARD QUNIT ROUTE: #{for_wizard_qunit_route}"
      obj[:script_src] = :unsafe_eval if for_wizard_qunit_route
    end
  end
end
