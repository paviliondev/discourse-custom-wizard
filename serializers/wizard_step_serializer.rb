module CustomWizardStepSerializerExtension
  extend ActiveSupport::Concern
  
  def self.prepended(klass)
    klass.class_eval do
      attributes :permitted, :permitted_message
    end
  end

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
  prepend CustomWizardStepSerializerExtension if SiteSetting.custom_wizard_enabled
end