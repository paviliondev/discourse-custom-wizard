# frozen_string_literal: true

class CustomWizard::FieldSerializer < ::WizardFieldSerializer
  
  attributes :image,
             :file_types,
             :limit,
             :property,
             :content
               
  def label
    return object.label if object.label.present?
    I18n.t("#{object.key || i18n_key}.label", default: '')
  end

  def description
    return object.description if object.description.present?
    I18n.t("#{object.key || i18n_key}.description", default: '', base_url: Discourse.base_url)
  end

  def image
    object.image
  end

  def include_image?
    object.image.present?
  end

  def placeholder
    I18n.t("#{object.key || i18n_key}.placeholder", default: '')
  end

  def file_types
    object.file_types
  end
  
  def limit
    object.limit
  end
  
  def property
    object.property
  end
  
  def content
    object.content
  end
  
  def include_choices?
    object.choices.present?
  end
end