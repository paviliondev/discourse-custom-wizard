module CustomWizardStepExtension
  attr_accessor :title, :description, :key, :permitted, :permitted_message
end

class Wizard::Step
  prepend CustomWizardStepExtension if SiteSetting.custom_wizard_enabled
end