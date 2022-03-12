# frozen_string_literal: true

class CustomWizard::WizardSerializer < CustomWizard::BasicWizardSerializer

  attributes :start,
             :background,
             :submission_last_updated_at,
             :theme_id,
             :completed,
             :required,
             :permitted,
             :uncategorized_category_id,
             :categories,
             :resume_on_revisit

  has_many :steps, serializer: ::CustomWizard::StepSerializer, embed: :objects
  has_one :user, serializer: ::BasicUserSerializer, embed: :objects
  has_many :groups, serializer: ::BasicGroupSerializer, embed: :objects

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

  def start
    object.start
  end

  def include_start?
    include_steps? && object.start.present?
  end

  def submission_last_updated_at
    object.current_submission.updated_at
  end

  def include_steps?
    !include_completed?
  end

  def include_categories?
    object.needs_categories
  end

  def include_groups?
    object.needs_groups
  end

  def uncategorized_category_id
    SiteSetting.uncategorized_category_id
  end

  def include_uncategorized_category_id?
    object.needs_categories
  end

  def categories
    object.categories.map { |c| c.to_h }
  end
end
