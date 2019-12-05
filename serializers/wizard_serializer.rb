module CustomWizardWizardSerializerExtension
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
  
  def include_name?
    object.respond_to?(:name)
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

class WizardSerializer
  prepend CustomWizardWizardSerializerExtension if SiteSetting.custom_wizard_enabled
end