# frozen_string_literal: true

## 
# type:        step
# number:      8
# title:       Add it to the serializer
# description: We want our new attribute to be serialized to the wizard client... 
##

class CustomWizard::FieldSerializer < ::WizardFieldSerializer

  attributes :image,
             :file_types,
             :format,
             :limit,
             :property,
             :content,
             :validations,
             :max_length,
             :char_counter,
             :number

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

  def format
    object.format
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

  def validations
    validations = {}
    object.validations&.each do |type, props|
      next unless props["status"]
      validations[props["position"]] ||= {}
      validations[props["position"]][type] = props.merge CustomWizard::RealtimeValidation.types[type.to_sym]
    end

    validations
  end

  def max_length
    object.max_length
  end

  def char_counter
    object.char_counter
  end

  def number
    object.number
  end
end
