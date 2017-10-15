require_dependency 'wizard/field'
require_dependency 'wizard/step'

::Wizard::Field.class_eval do
  attr_reader :label, :description, :key, :min_length

  def initialize(attrs)
    attrs = attrs || {}

    @id = attrs[:id]
    @type = attrs[:type]
    @required = !!attrs[:required]
    @label = attrs[:label]
    @description = attrs[:description]
    @key = attrs[:key]
    @min_length = attrs[:min_length]
    @value = attrs[:value]
    @choices = []
  end
end

class ::Wizard::Step
  attr_accessor :title, :description, :key
end

::WizardSerializer.class_eval do
  attributes :id, :background, :completed

  def id
    object.id
  end

  def background
    object.background
  end

  def completed
    object.completed?
  end

  def include_completed?
    object.completed? && !object.multiple_submissions && !scope.current_user.admin?
  end

  def include_start?
    object.start && include_steps?
  end

  def include_steps?
    !include_completed?
  end
end

::WizardStepSerializer.class_eval do
  def title
    return object.title if object.title
    I18n.t("#{object.key || i18n_key}.title", default: '')
  end

  def description
    return object.description if object.description
    I18n.t("#{object.key || i18n_key}.description", default: '')
  end
end

::WizardFieldSerializer.class_eval do
  def label
    return object.label if object.label
    I18n.t("#{object.key || i18n_key}.label", default: '')
  end

  def description
    return object.description if object.description
    I18n.t("#{object.key || i18n_key}.description", default: '')
  end

  def placeholder
    I18n.t("#{object.key || i18n_key}.placeholder", default: '')
  end
end
