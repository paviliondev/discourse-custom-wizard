module CustomWizardWizardStepSerializerExtension
  attributes :permitted, :permitted_message

  def title
    return PrettyText.cook(object.title) if object.title
    PrettyText.cook(I18n.t("#{object.key || i18n_key}.title", default: ''))
  end

  def description
    return object.description if object.description
    PrettyText.cook(I18n.t("#{object.key || i18n_key}.description", default: '', base_url: Discourse.base_url))
  end

  def permitted
    object.permitted
  end
  
  def permitted_message
    object.permitted_message
  end
end

class WizardStepSerializer
  prepend CustomWizardWizardStepSerializerExtension if SiteSetting.custom_wizard_enabled
end