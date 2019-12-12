# frozen_string_literal: true

class CustomWizardSerializer < ::WizardSerializer
  
  attributes :id,
             :name,
             :background,
             :completed,
             :required,
             :min_trust,
             :permitted,
             :uncategorized_category_id
  
  has_one :user, serializer: ::BasicUserSerializer, embed: :objects           
  has_many :steps, serializer: ::CustomWizardStepSerializer, embed: :objects
  has_many :categories, serializer: ::BasicCategorySerializer, embed: :objects

  def completed
    object.completed?
  end

  def include_completed?
    object.completed? &&
    (!object.respond_to?(:multiple_submissions) || !object.multiple_submissions) &&
    !scope.is_admin?
  end

  def permitted
    object.permitted?
  end

  def include_start?
    object.start && include_steps?
  end

  def include_steps?
    !include_completed?
  end
  
  def include_categories?
    object.needs_categories
  end
  
  def uncategorized_category_id
    SiteSetting.uncategorized_category_id
  end
  
  def include_uncategorized_category_id?
    object.needs_categories
  end
end