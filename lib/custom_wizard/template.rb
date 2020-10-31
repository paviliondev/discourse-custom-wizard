class CustomWizard::Template
  def self.add(obj)
    wizard = obj.is_a?(String) ? ::JSON.parse(json) : obj
    PluginStore.set('custom_wizard', wizard["id"], wizard)
  end

  def self.find(wizard_id)
    PluginStore.get('custom_wizard', wizard_id)
  end
  
  def self.save(data)
    data = data.with_indifferent_access
    existing = self.find(data[:id])
    
    data[:steps].each do |step|
      if step[:raw_description]
        step[:description] = PrettyText.cook(step[:raw_description])
      end
    end
    
    data = data.slice!(:create)
    
    ActiveRecord::Base.transaction do
      PluginStore.set('custom_wizard', data[:id], data)
      
      if data[:after_time]
        Jobs.cancel_scheduled_job(:set_after_time_wizard, wizard_id: data[:id])
        enqueue_at = Time.parse(data[:after_time_scheduled]).utc
        Jobs.enqueue_at(enqueue_at, :set_after_time_wizard, wizard_id: data[:id])
      end

      if existing && existing[:after_time] && !data[:after_time]
        Jobs.cancel_scheduled_job(:set_after_time_wizard, wizard_id: data[:id])
        Jobs.enqueue(:clear_after_time_wizard, wizard_id: data[:id])
      end
    end
    
    data[:id]
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
  
  def self.list(user=nil)
    PluginStoreRow.where(plugin_name: 'custom_wizard').order(:id)
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
  
  def self.setting_enabled(attr)
    PluginStoreRow.where("
      plugin_name = 'custom_wizard' AND
      (value::json ->> '#{attr}')::boolean IS TRUE
    ")
  end
end