require_dependency 'wizard/step'
require_dependency 'wizard/field'
require_dependency 'wizard/step_updater'
require_dependency 'wizard/builder'

UserHistory.actions[:custom_wizard_step] = 1000

class CustomWizard::Wizard
  include ActiveModel::SerializerSupport

  attr_reader :steps, :user
  attr_accessor :id,
                :name,
                :background,
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
                :needs_groups

  def initialize(user=nil, attrs = {})
    @steps = []
    @user = user
    @first_step = nil
    @required = false
    @needs_categories = false
    @needs_groups = false
    
    attrs.each do |key, value|
      setter = "#{key}="
      send(setter, value) if respond_to?(setter.to_sym, false)
    end
  end

  def create_step(step_name)
    ::Wizard::Step.new(step_name)
  end

  def append_step(step)
    step = create_step(step) if step.is_a?(String)

    yield step if block_given?

    last_step = @steps.last

    @steps << step

    # If it's the first step
    if @steps.size == 1
      @first_step = step
      step.index = 0
    elsif last_step.present?
      last_step.next = step
      step.previous = last_step
      step.index = last_step.index + 1
    end
  end

  def start
    return nil if !@user

    if unfinished? && last_completed_step = ::UserHistory.where(
        acting_user_id: @user.id,
        action: ::UserHistory.actions[:custom_wizard_step],
        context: @id,
        subject: @steps.map(&:id)
      ).order("created_at").last

      step_id = last_completed_step.subject
      last_index = @steps.index { |s| s.id == step_id }
      @steps[last_index + 1]
    else
      @first_step
    end
  end

  def create_updater(step_id, fields)
    step = @steps.find { |s| s.id == step_id }
    wizard = self
    CustomWizard::StepUpdater.new(@user, wizard, step, fields)
  end

  def unfinished?
    return nil if !@user

    most_recent = ::UserHistory.where(
      acting_user_id: @user.id,
      action: ::UserHistory.actions[:custom_wizard_step],
      context: @id,
    ).distinct.order('updated_at DESC').first

    if most_recent && most_recent.subject == "reset"
      false
    elsif most_recent
      last_finished_step = most_recent.subject
      last_step = CustomWizard::Wizard.step_ids(@id).last
      last_finished_step != last_step
    else
      true
    end
  end

  def completed?
    return nil if !@user

    steps = CustomWizard::Wizard.step_ids(@id)

    history = ::UserHistory.where(
      acting_user_id: @user.id,
      action: ::UserHistory.actions[:custom_wizard_step],
      context: @id
    )

    if @after_time
      history = history.where("updated_at > ?", @after_time_scheduled)
    end

    completed = history.distinct.order(:subject).pluck(:subject)

    (steps - completed).empty?
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
      if m.type === 'assignment'
        GroupUser.exists?(group_id: m.result, user_id: user.id)
      elsif m.type === 'validation'
        mapper.result
      else
        true
      end
    end
  end

  def reset
    ::UserHistory.create(
      action: ::UserHistory.actions[:custom_wizard_step],
      acting_user_id: @user.id,
      context: @id,
      subject: "reset"
    )
  end
  
  def categories
    @categories ||= ::Site.new(Guardian.new(@user)).categories
  end
  
  def groups
    @groups ||= ::Site.new(Guardian.new(@user)).groups
  end
  
  def self.filter_records(filter)
    PluginStoreRow.where("
      plugin_name = 'custom_wizard' AND
      (value::json ->> '#{filter}')::boolean IS TRUE
    ")
  end

  def self.after_signup(user)
    if (records = filter_records('after_signup')).any?
      result = false
      
      records
        .sort_by { |record| record.value['permitted'].present? ? 0 : 1 }
        .each do |record|
          wizard = CustomWizard::Wizard.new(user, JSON.parse(record.value))
                    
          if wizard.permitted?
            result = wizard
            break
          end
        end
        
      result
    else
      false
    end
  end

  def self.prompt_completion(user)
    if (records = filter_records('prompt_completion')).any?
      records.reduce([]) do |result, record|
        wizard = CustomWizard::Wizard.new(user, ::JSON.parse(record.value))
        result.push(id: wizard.id, name: wizard.name) if !wizard.completed?
        result
      end
    else
      false
    end
  end

  def self.restart_on_revisit
    if (records = filter_records('restart_on_revisit')).any?
      records.first.key
    else
      false
    end
  end

  def self.steps(wizard_id)
    wizard = PluginStore.get('custom_wizard', wizard_id)
    wizard ? wizard['steps'] : nil
  end

  def self.step_ids(wizard_id)
    steps = self.steps(wizard_id)
    return [] if !steps
    steps.map { |s| s['id'] }.flatten.uniq
  end

  def self.field_ids(wizard_id, step_id)
    steps = self.steps(wizard_id)
    return [] if !steps
    step = steps.select { |s| s['id'] === step_id }.first
    if step && fields = step['fields']
      fields.map { |f| f['id'] }
    else
      []
    end
  end

  def self.add_wizard(obj)
    wizard = obj.is_a?(String) ? ::JSON.parse(json) : obj
    PluginStore.set('custom_wizard', wizard["id"], wizard)
  end

  def self.find(wizard_id)
    PluginStore.get('custom_wizard', wizard_id)
  end

  def self.exists?(wizard_id)
    PluginStoreRow.exists?(plugin_name: 'custom_wizard', key: wizard_id)
  end

  def self.create(user, wizard_id)
    CustomWizard::Wizard.new(user, self.find(wizard_id).to_h)
  end

  def self.set_submission_redirect(user, wizard_id, url)
    PluginStore.set("#{wizard_id.underscore}_submissions", user.id, [{ redirect_to: url }])
  end

  def self.set_wizard_redirect(user, wizard_id)
    wizard = CustomWizard::Wizard.create(user, wizard_id)

    if wizard.permitted?
      user.custom_fields['redirect_to_wizard'] = wizard_id
      user.save_custom_fields(true)
    else
      false
    end
  end
end
