module CustomWizardChoiceExtension
  def initialize(id, opts)
    @id = id
    @opts = opts
    @data = opts[:data]
    @extra_label = opts[:extra_label]
    @icon = opts[:icon]
  end

  def label
    @label ||= PrettyText.cook(@opts[:label])
  end
end

class Wizard::Choice
  prepend CustomWizardChoiceExtension if SiteSetting.custom_wizard_enabled
end