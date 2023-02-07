# frozen_string_literal: true
require_dependency 'wizard/step'
require_dependency 'wizard/field'
require_dependency 'wizard/step_updater'
require_dependency 'wizard/builder'

class CustomWizard::Wizard
  include ActiveModel::SerializerSupport

  attr_accessor :id,
                :name,
                :background,
                :theme_id,
                :save_submissions,
                :multiple_submissions,
                :after_time,
                :after_time_scheduled,
                :after_signup,
                :required,
                :prompt_completion,
                :restart_on_revisit,
                :resume_on_revisit,
                :permitted,
                :steps,
                :step_ids,
                :field_ids,
                :first_step,
                :start,
                :actions,
                :action_ids,
                :user,
                :guest_id,
                :submissions,
                :template

  attr_reader   :all_step_ids

  GUEST_ID_PREFIX ||= "guest"
  GUEST_GROUP_ID = -1

  def initialize(attrs = {}, user = nil, guest_id = nil)
    if user
      @user = user
    elsif guest_id
      @guest_id = guest_id
    end

    attrs = attrs.with_indifferent_access

    @id = attrs['id']
    @name = attrs['name']
    @background = attrs['background']
    @save_submissions = cast_bool(attrs['save_submissions'])
    @multiple_submissions = cast_bool(attrs['multiple_submissions'])
    @prompt_completion = cast_bool(attrs['prompt_completion'])
    @restart_on_revisit = cast_bool(attrs['restart_on_revisit'])
    @resume_on_revisit = cast_bool(attrs['resume_on_revisit'])
    @after_signup = cast_bool(attrs['after_signup'])
    @after_time = cast_bool(attrs['after_time'])
    @after_time_scheduled = attrs['after_time_scheduled']
    @required = cast_bool(attrs['required'])
    @permitted = attrs['permitted'] || nil
    @theme_id = attrs['theme_id']

    if attrs['theme'].present?
      theme = ::Theme.find_by(name: attrs['theme'])
      @theme_id = theme.id if theme
    end

    @first_step = nil
    @steps = []

    if attrs['steps'].present?
      @step_ids = @all_step_ids = attrs['steps'].map { |s| s['id'] }

      @field_ids = []
      attrs['steps'].each do |step|
        if step['fields'].present?
          step['fields'].each do |field|
            @field_ids << field['id']
          end
        end
      end
    end

    @actions = attrs['actions'] || []
    @action_ids = @actions.map { |a| a['id'] }
    @template = attrs
  end

  def actor_id
    user ? user.id : guest_id
  end

  def cast_bool(val)
    val.nil? ? false : ActiveRecord::Type::Boolean.new.cast(val)
  end

  def create_step(step_id)
    ::CustomWizard::Step.new(step_id)
  end

  def append_step(step)
    step = create_step(step) if step.is_a?(String)

    yield step if block_given?

    steps << step
    step.wizard = self
    step.index = (steps.size == 1 ? 0 : steps.size) if step.index.nil?
  end

  def update!
    update_step_order
    update_step_ids
    update_field_ids
    update_action_ids

    @submissions = nil
    @current_submission = nil

    true
  end

  def update_step_order
    steps.sort_by!(&:index)

    steps.each_with_index do |step, index|
      if index === 0
        @first_step = step
        @start = step.id
      else
        last_step = steps[index - 1]
        last_step.next = step
        step.previous = last_step
      end

      step.index = index

      if index === (steps.length - 1)
        step.conditional_final_step = true
      end

      if index === (all_step_ids.length - 1)
        step.last_step = true
      end

      if step.previous && step.previous.id === last_completed_step_id
        @start = step.id
      end
    end
  end

  def last_completed_step_id
    return nil unless actor_id && unfinished?

    last_completed_step = CustomWizard::UserHistory.where(
      actor_id: actor_id,
      action: CustomWizard::UserHistory.actions[:step],
      context: id,
      subject: all_step_ids
    ).order("created_at").last

    last_completed_step&.subject
  end

  def find_step(step_id)
    steps.select { |step| step.id === step_id }.first
  end

  def create_updater(step_id, submission)
    step = @steps.find { |s| s.id == step_id }
    wizard = self
    CustomWizard::StepUpdater.new(wizard, step, submission)
  end

  def unfinished?
    return nil unless actor_id

    most_recent = CustomWizard::UserHistory.where(
      actor_id: actor_id,
      action: CustomWizard::UserHistory.actions[:step],
      context: id,
    ).distinct.order('updated_at DESC').first

    if most_recent && most_recent.subject == "reset"
      false
    elsif most_recent
      most_recent.subject != steps.last.id
    else
      true
    end
  end

  def completed?
    return nil unless actor_id

    history = CustomWizard::UserHistory.where(
      actor_id: actor_id,
      action: CustomWizard::UserHistory.actions[:step],
      context: id
    )

    if after_time
      history = history.where("updated_at > ?", after_time_scheduled)
    end

    completed = history.distinct.order(:subject).pluck(:subject)
    (step_ids - completed).empty?
  end

  def permitted?
    return nil unless actor_id
    return true if user && (user.admin? || permitted.blank?)
    return false if !user && permitted.blank?

    mapper = CustomWizard::Mapper.new(
      inputs: permitted,
      user: user,
      opts: {
        with_type: true,
        multiple: true
      }
    ).perform

    return true if mapper.blank?

    mapper.all? do |m|
      if !user
        m[:type] === 'assignment' && [*m[:result]].include?(GUEST_GROUP_ID)
      else
        if m[:type] === 'assignment'
          [*m[:result]].include?(Group::AUTO_GROUPS[:everyone]) ||
          GroupUser.exists?(group_id: m[:result], user_id: user.id)
        elsif m[:type] === 'validation'
          m[:result]
        else
          true
        end
      end
    end
  end

  def can_access?
    permitted? && (multiple_submissions || !completed?)
  end

  def reset
    return nil unless actor_id

    CustomWizard::UserHistory.create(
      action: CustomWizard::UserHistory.actions[:step],
      actor_id: actor_id,
      context: id,
      subject: "reset"
    )
  end

  def update_step_ids
    @step_ids = steps.map(&:id)
  end

  def update_field_ids
    @field_ids = steps.map { |step| step.fields.map { |field| field.id } }.flatten
  end

  def update_action_ids
    @action_ids = []

    @actions.each do |action|
      if action['run_after'].blank? ||
         action['run_after'] === 'wizard_completion' ||
         step_ids.include?(action['run_after'])

        @action_ids << action['id']
      end
    end
  end

  def submissions
    @submissions ||= CustomWizard::Submission.list(self).submissions
  end

  def current_submission
    @current_submission ||= begin
      if submissions.present?
        unsubmitted = submissions.select { |submission| !submission.submitted_at }
        unsubmitted.present? ? unsubmitted.first : CustomWizard::Submission.new(self)
      else
        CustomWizard::Submission.new(self)
      end
    end
  end

  def cleanup_on_complete!
    remove_user_redirect

    if current_submission.present?
      current_submission.submitted_at = Time.now.iso8601
      current_submission.save
    end

    update!
  end

  def cleanup_on_skip!
    remove_user_redirect

    if current_submission.present?
      current_submission.remove
    end

    reset
  end

  def remove_user_redirect
    return unless user.present?

    if id == user.redirect_to_wizard
      user.custom_fields.delete('redirect_to_wizard')
      user.save_custom_fields(true)
    end
  end

  def self.create(wizard_id, user = nil, guest_id = nil)
    if template = CustomWizard::Template.find(wizard_id)
      new(template.to_h, user, guest_id)
    else
      false
    end
  end

  def self.list(user, template_opts = {}, not_completed = false)
    return [] unless user

    CustomWizard::Template.list(**template_opts).reduce([]) do |result, template|
      wizard = new(template, user)
      result.push(wizard) if wizard.can_access? && (
        !not_completed || !wizard.completed?
      )
      result
    end
  end

  def self.after_signup(user)
    wizards = list(
      user,
      {
        setting: 'after_signup',
        order: "(value::json ->> 'permitted') IS NOT NULL DESC"
      }
    )
    wizards.any? ? wizards.first : false
  end

  def self.prompt_completion(user)
    wizards = list(
      user,
      {
        setting: 'prompt_completion',
        order: "(value::json ->> 'permitted') IS NOT NULL DESC"
      },
      true
    )
    if wizards.any?
      wizards.map do |w|
        {
          id: w.id,
          name: w.name
        }
      end
    else
      false
    end
  end

  def self.set_user_redirect(wizard_id, user)
    wizard = self.create(wizard_id, user)

    if wizard.permitted?
      user.custom_fields['redirect_to_wizard'] = wizard_id
      user.save_custom_fields(true)
    else
      false
    end
  end

  def self.set_wizard_redirect(user, wizard_id, url)
    wizard = self.create(wizard_id, user)

    if wizard.permitted?
      submission = wizard.current_submission
      submission.redirect_to = url
      submission.save
    else
      false
    end
  end

  def self.generate_guest_id
    "#{self::GUEST_ID_PREFIX}_#{SecureRandom.hex(12)}"
  end
end
