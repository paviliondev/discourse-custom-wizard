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
                :actions,
                :user

  def initialize(attrs = {}, user=nil)
    @user = user
  
    @id = attrs['id']
    @name = attrs['name']
    @background = attrs['background']
    @save_submissions = attrs['save_submissions'] || false
    @multiple_submissions = attrs['multiple_submissions'] || false
    @prompt_completion = attrs['prompt_completion'] || false
    @restart_on_revisit = attrs['restart_on_revisit'] || false
    @after_signup = attrs['after_signup']
    @after_time = attrs['after_time']
    @after_time_scheduled = attrs['after_time_scheduled']
    @required = attrs['required'] || false
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
    @actions = []
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
    return true if user.admin
    return permitted? && (multiple_submissions || !completed?)
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
  
  def submissions
    Array.wrap(PluginStore.get("#{id}_submissions", @user.id))
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
          wizard = self.new(JSON.parse(record.value), user)
          
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
        wizard = CustomWizard::Wizard.new(::JSON.parse(record.value), user)
        
        if wizard.permitted? && !wizard.completed?
          result.push(id: wizard.id, name: wizard.name) 
        end
        
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
  
  def self.list(user=nil)
    PluginStoreRow.where(plugin_name: 'custom_wizard').order(:id)
      .reduce([]) do |result, record|
        attrs = JSON.parse(record.value)
        
        if attrs.present? &&
          attrs.is_a?(Hash) &&
          attrs['id'].present? &&
          attrs['name'].present?
          
          result.push(self.new(attrs, user))
        end
        
        result
      end
  end
  
  def self.save(wizard)
    existing_wizard = self.create(wizard[:id])
    
    wizard[:steps].each do |step|
      if step[:raw_description]
        step[:description] = PrettyText.cook(step[:raw_description])
      end
    end
    
    wizard = wizard.slice!(:create)
    
    ActiveRecord::Base.transaction do
      PluginStore.set('custom_wizard', wizard[:id], wizard)
      
      if wizard[:after_time]
        Jobs.cancel_scheduled_job(:set_after_time_wizard, wizard_id: wizard[:id])
        enqueue_at = Time.parse(wizard[:after_time_scheduled]).utc
        Jobs.enqueue_at(enqueue_at, :set_after_time_wizard, wizard_id: wizard[:id])
      end

      if existing_wizard && existing_wizard.after_time && !wizard[:after_time]
        Jobs.cancel_scheduled_job(:set_after_time_wizard, wizard_id: wizard[:id])
        Jobs.enqueue(:clear_after_time_wizard, wizard_id: wizard[:id])
      end
    end
    
    wizard[:id]
  end
  
  def self.remove(wizard_id)
    wizard = self.create(wizard_id)
    
    ActiveRecord::Base.transaction do
      if wizard.after_time
        Jobs.cancel_scheduled_job(:set_after_time_wizard)
        Jobs.enqueue(:clear_after_time_wizard, wizard_id: wizard.id)
      end
      
      PluginStore.remove('custom_wizard', wizard.id)
    end
  end

  def self.exists?(wizard_id)
    PluginStoreRow.exists?(plugin_name: 'custom_wizard', key: wizard_id)
  end

  def self.create(wizard_id, user = nil)
    if wizard = self.find(wizard_id)
      self.new(wizard.to_h, user)
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
  
  def self.register_styles
    full_path = "#{Rails.root}/plugins/discourse-custom-wizard/assets/stylesheets/wizard/wizard_custom.scss"
    DiscoursePluginRegistry.register_asset(full_path, {}, "wizard_custom")
    Stylesheet::Importer.register_import("wizard_custom") do
      import_files(DiscoursePluginRegistry.stylesheets["wizard_custom"])
    end
  end
end
