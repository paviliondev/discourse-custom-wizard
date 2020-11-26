require_dependency 'wizard/step'
require_dependency 'wizard/field'
require_dependency 'wizard/step_updater'
require_dependency 'wizard/builder'

UserHistory.actions[:custom_wizard_step] = 1000

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
                :permitted,
                :needs_categories,
                :needs_groups,
                :steps,
                :step_ids,
                :actions,
                :user,
                :first_step

  def initialize(attrs = {}, user=nil)
    @user = user
    attrs = attrs.with_indifferent_access
  
    @id = attrs['id']
    @name = attrs['name']
    @background = attrs['background']
    @save_submissions = cast_bool(attrs['save_submissions'])
    @multiple_submissions = cast_bool(attrs['multiple_submissions'])
    @prompt_completion = cast_bool(attrs['prompt_completion'])
    @restart_on_revisit = cast_bool(attrs['restart_on_revisit'])
    @after_signup = cast_bool(attrs['after_signup'])
    @after_time = cast_bool(attrs['after_time'])
    @after_time_scheduled = attrs['after_time_scheduled']
    @required = cast_bool(attrs['required'])
    @permitted = attrs['permitted'] || nil
    @needs_categories = false
    @needs_groups = false
    @theme_id = attrs['theme_id']
    
    if attrs['theme'].present?
      theme = ::Theme.find_by(name: attrs['theme'])
      @theme_id = theme.id if theme
    end
    
    @first_step = nil
    @steps = []
    if attrs['steps'].present?
      @step_ids = attrs['steps'].map { |s| s['id'] }
    end
    
    @actions = []
  end
  
  def cast_bool(val)
    val.nil? ? false : ActiveRecord::Type::Boolean.new.cast(val)
  end

  def create_step(step_name)
    ::Wizard::Step.new(step_name)
  end

  def append_step(step)
    step = create_step(step) if step.is_a?(String)
    
    yield step if block_given?

    last_step = steps.last
    steps << step
        
    if steps.size == 1
      @first_step = step
      step.index = 0
    elsif last_step.present?
      last_step.next = step
      step.previous = last_step
      step.index = last_step.index + 1
    end
  end

  def start
    return nil if !user

    if unfinished? && last_completed_step = ::UserHistory.where(
        acting_user_id: user.id,
        action: ::UserHistory.actions[:custom_wizard_step],
        context: id,
        subject: steps.map(&:id)
      ).order("created_at").last

      step_id = last_completed_step.subject
      last_index = steps.index { |s| s.id == step_id }
      steps[last_index + 1]
    else
      @first_step
    end
  end

  def create_updater(step_id, submission)
    step = @steps.find { |s| s.id == step_id }
    wizard = self
    CustomWizard::StepUpdater.new(user, wizard, step, submission)
  end

  def unfinished?
    return nil if !user

    most_recent = ::UserHistory.where(
      acting_user_id: user.id,
      action: ::UserHistory.actions[:custom_wizard_step],
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
    return nil if !user
    
    history = ::UserHistory.where(
      acting_user_id: user.id,
      action: ::UserHistory.actions[:custom_wizard_step],
      context: id
    )

    if after_time
      history = history.where("updated_at > ?", after_time_scheduled)
    end
    
    completed = history.distinct.order(:subject).pluck(:subject)
    (step_ids - completed).empty?
  end

  def permitted?
    return false unless user
    return true if user.admin? || permitted.blank?
    
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
      if m[:type] === 'assignment'
        GroupUser.exists?(group_id: m[:result], user_id: user.id)
      elsif m[:type] === 'validation'
        m[:result]
      else
        true
      end
    end
  end
  
  def can_access?
    return false unless user
    return true if user.admin
    return permitted? && (multiple_submissions || !completed?)
  end

  def reset
    ::UserHistory.create(
      action: ::UserHistory.actions[:custom_wizard_step],
      acting_user_id: user.id,
      context: id,
      subject: "reset"
    )
  end
  
  def categories
    @categories ||= ::Site.new(Guardian.new(user)).categories
  end
  
  def groups
    @groups ||= ::Site.new(Guardian.new(user)).groups
  end
  
  def submissions
    Array.wrap(PluginStore.get("#{id}_submissions", user.id))
  end
  
  def current_submission
    if submissions.present? && !submissions.last.key?("submitted_at")
      submissions.last
    else
      nil
    end
  end
  
  def set_submissions(submissions)
    PluginStore.set("#{id}_submissions", user.id, Array.wrap(submissions))
  end
  
  def self.submissions(wizard_id, user)
    new({ id: wizard_id }, user).submissions
  end
  
  def self.set_submissions(wizard_id, user, submissions)
    new({ id: wizard_id }, user).set_submissions(submissions)
  end
  
  def self.create(wizard_id, user = nil)
    if template = CustomWizard::Template.find(wizard_id)
      new(template.to_h, user)
    else
      false
    end
  end
  
  def self.list(user, template_opts: {})
    return [] unless user
    
    CustomWizard::Template.list(template_opts).reduce([]) do |result, template|
      wizard = new(template, user)
      result.push(wizard) if wizard.can_access?
      result
    end
  end

  def self.after_signup(user)
    wizards = list(
      user,
      template_opts: {
        setting: 'after_signup',
        order: "(value::json ->> 'permitted') IS NOT NULL DESC"
      }
    )
    wizards.any? ? wizards.first : false
  end

  def self.prompt_completion(user)
    wizards = list(
      user,
      template_opts: {
        setting: 'prompt_completion',
        order: "(value::json ->> 'permitted') IS NOT NULL DESC"
      }
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

  def self.set_submission_redirect(user, wizard_id, url)
    PluginStore.set("#{wizard_id.underscore}_submissions", user.id, [{ redirect_to: url }])
  end

  def self.set_wizard_redirect(wizard_id, user)
    wizard = self.create(wizard_id, user)
    
    if wizard.permitted?
      user.custom_fields['redirect_to_wizard'] = wizard_id
      user.save_custom_fields(true)
    else
      false
    end
  end
end
