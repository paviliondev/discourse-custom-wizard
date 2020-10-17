class ::CustomWizard::CustomFields
  include HasErrors
  include ActiveModel::Serialization
  
  CLASSES ||= ["topic", "user", "group", "category"]
  ATTRS ||= ["name", "klass", "type"]
  KEY ||= "custom_wizard_custom_fields"
  
  def initialize(data)
    data = data.with_indifferent_access
    
    ATTRS.each do |attr|
      self.class.class_eval { attr_accessor attr }     
      send("#{attr}=", data[attr]) if data[attr].present? 
    end
  end

  def save
    validate

    if valid?
      data = {}
      name = nil
      
      ATTRS.each do |attr|
        value = send(attr)
        
        if attr == 'name'
          name = value
        else
          data[attr] = value
        end
      end
      
      PluginStore.set(KEY, name, data)
    else
      false
    end
  end
  
  def validate
    ATTRS.each do |attr|
      value = send(attr)
      add_error("Attribute required: #{attr}") if value.blank?
      add_error("Unsupported class: #{value}") if CLASSES.exclude?(value)
    end
  end
  
  def valid?
    errors.blank?
  end
  
  def self.list
    PluginStoreRow.where(plugin_name: KEY)
      .map do |record|
        data = JSON.parse(record.value)
        data[:name] = record.key
        self.new(data)
      end
  end
end