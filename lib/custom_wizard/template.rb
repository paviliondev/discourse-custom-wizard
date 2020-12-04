# frozen_string_literal: true

class CustomWizard::Template
  include HasErrors
  
  attr_reader :data,
              :opts
  
  def initialize(data)
    @data = data
  end
  
  def save(opts={})
    @opts = opts
    
    normalize_data
    validate_data
    prepare_data
    
    return false if errors.any?
        
    ActiveRecord::Base.transaction do
      schedule_save_jobs unless opts[:skip_jobs]
      PluginStore.set(CustomWizard::PLUGIN_NAME, @data[:id], @data)
    end
    
    @data[:id]
  end
  
  def self.save(data, opts={})
    new(data).save(opts)
  end
  
  def self.find(wizard_id)
    PluginStore.get(CustomWizard::PLUGIN_NAME, wizard_id)
  end
  
  def self.remove(wizard_id)
    wizard = CustomWizard::Wizard.create(wizard_id)
    
    return false if !wizard
    
    ActiveRecord::Base.transaction do      
      PluginStore.remove(CustomWizard::PLUGIN_NAME, wizard.id)
      
      if wizard.after_time
        Jobs.cancel_scheduled_job(:set_after_time_wizard)
        Jobs.enqueue(:clear_after_time_wizard, wizard_id: wizard_id)
      end
    end
    
    true
  end
  
  def self.exists?(wizard_id)
    PluginStoreRow.exists?(plugin_name: 'custom_wizard', key: wizard_id)
  end
  
  def self.list(setting: nil, order: :id)
    query = "plugin_name = 'custom_wizard'"
    query += "AND (value::json ->> '#{setting}')::boolean IS TRUE" if setting
    
    PluginStoreRow.where(query).order(order)
      .reduce([]) do |result, record|
        attrs = JSON.parse(record.value)
        
        if attrs.present? &&
          attrs.is_a?(Hash) &&
          attrs['id'].present? &&
          attrs['name'].present?
          
          result.push(attrs)
        end
        
        result
      end
  end
  
  private
  
  def normalize_data
    @data = ::JSON.parse(@data) if @data.is_a?(String)
    @data = @data.with_indifferent_access
  end
  
  def prepare_data
    @data[:steps].each do |step|
      if step[:raw_description]
        step[:description] = PrettyText.cook(step[:raw_description])
      end
    end
  end
  
  def validate_data
    validator = CustomWizard::TemplateValidator.new(@data, @opts)
    validator.perform
    add_errors_from(validator)
  end
  
  def schedule_save_jobs
    if @data[:after_time] && @data[:after_time_scheduled]
      wizard_id = @data[:id]
      old_data = CustomWizard::Template.find(data[:id])
      
      begin
        enqueue_wizard_at = Time.parse(@data[:after_time_scheduled]).utc
      rescue ArgumentError
        errors.add :validation, I18n.t("wizard.validation.after_time")
        raise ActiveRecord::Rollback.new
      end
      
      if enqueue_wizard_at
        Jobs.cancel_scheduled_job(:set_after_time_wizard, wizard_id: wizard_id)
        Jobs.enqueue_at(enqueue_wizard_at, :set_after_time_wizard, wizard_id: wizard_id)
      elsif old_data && old_data[:after_time]
        Jobs.cancel_scheduled_job(:set_after_time_wizard, wizard_id: wizard_id)
        Jobs.enqueue(:clear_after_time_wizard, wizard_id: wizard_id)
      end
    end
  end
end