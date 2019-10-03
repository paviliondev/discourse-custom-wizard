require_dependency 'wizard'
require_dependency 'wizard/field'
require_dependency 'wizard/step'

::Wizard.class_eval do
  def self.user_requires_completion?(user)
    wizard_result = self.new(user).requires_completion?
    return wizard_result if wizard_result

    custom_redirect = false

    if user && user.first_seen_at.blank? && wizard_id = CustomWizard::Wizard.after_signup
      wizard = CustomWizard::Wizard.create(user, wizard_id)

      if !wizard.completed? && wizard.permitted?
        custom_redirect = true
        CustomWizard::Wizard.set_wizard_redirect(user, wizard_id)
      end
    end

    !!custom_redirect
  end
end

::Wizard::Field.class_eval do
  attr_reader :label, :description, :image, :key, :min_length, :file_types, :limit, :property
  attr_accessor :dropdown_none

  def initialize(attrs)
    @attrs = attrs || {}
    @id = attrs[:id]
    @type = attrs[:type]
    @required = !!attrs[:required]
    @description = attrs[:description]
    @image = attrs[:image]
    @key = attrs[:key]
    @min_length = attrs[:min_length]
    @value = attrs[:value]
    @choices = []
    @dropdown_none = attrs[:dropdown_none]
    @file_types = attrs[:file_types]
    @limit = attrs[:limit]
    @property = attrs[:property]
  end

  def label
    @label ||= PrettyText.cook(@attrs[:label])
  end
end

::Wizard::Choice.class_eval do
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

class ::Wizard::Step
  attr_accessor :title, :description, :key, :permitted, :permitted_message
end

::WizardSerializer.class_eval do
  attributes :id,
             :name,
             :background,
             :completed,
             :required,
             :min_trust,
             :permitted,
             :user,
             :categories,
             :uncategorized_category_id

  def id
    object.id
  end

  def include_id?
    object.respond_to?(:id)
  end

  def name
    object.name
  end

  def background
    object.background
  end

  def include_background?
    object.respond_to?(:background)
  end

  def completed
    object.completed?
  end

  def include_completed?
    object.completed? &&
    (!object.respond_to?(:multiple_submissions) || !object.multiple_submissions) &&
    !scope.is_admin?
  end

  def min_trust
    object.min_trust
  end

  def include_min_trust?
    object.respond_to?(:min_trust)
  end

  def permitted
    object.permitted?
  end

  def include_permitted?
    object.respond_to?(:permitted?)
  end

  def include_start?
    object.start && include_steps?
  end

  def include_steps?
    !include_completed?
  end

  def required
    object.required
  end

  def include_required?
    object.respond_to?(:required)
  end

  def user
    object.user
  end
  
  def categories
    begin
      site = ::Site.new(scope)
      ::ActiveModel::ArraySerializer.new(site.categories, each_serializer: BasicCategorySerializer)
    rescue => e
      puts "HERE IS THE ERROR: #{e.inspect}"
    end
  end
  
  def uncategorized_category_id
    SiteSetting.uncategorized_category_id
  end
end

::WizardStepSerializer.class_eval do
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

::WizardFieldSerializer.class_eval do
  attributes :dropdown_none, :image, :file_types, :limit, :property

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

  def dropdown_none
    object.dropdown_none
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
end
