## TODO limit this to the first admin
module CustomWizardSiteSerializerExtension
  extend ActiveSupport::Concern
  
  def self.prepended(klass)
    klass.class_eval do
      attributes :complete_custom_wizard
    end
  end

  def include_wizard_required?
    scope.is_admin? && Wizard.new(scope.user).requires_completion?
  end

  def complete_custom_wizard
    if scope.user && requires_completion = CustomWizard::Wizard.prompt_completion(scope.user)
      requires_completion.map {|w| {name: w[:name], url: "/w/#{w[:id]}"}}
    end
  end

  def include_complete_custom_wizard?
    complete_custom_wizard.present?
  end
end

class SiteSerializer
  prepend CustomWizardSiteSerializerExtension if SiteSetting.custom_wizard_enabled
end