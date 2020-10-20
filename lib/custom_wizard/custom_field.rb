class ::CustomWizard::CustomField
  include HasErrors
  include ActiveModel::Serialization
  
  CLASSES ||= ["topic", "group", "category", "post"]
  SERIALIZERS ||= ["topic_view", "topic_list_item", "post", "basic_category"]
  TYPES ||= ["string", "boolean", "json"]
  ATTRS ||= ["name", "klass", "type", "serializers"]
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
          name = value.parameterize(separator: '_')
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
      
      if value.blank?
        add_error("Attribute required: #{attr}")
        next
      end
      
      if attr == 'klass' && CLASSES.exclude?(value)
        add_error("Unsupported class: #{value}")
      end
      
      if attr == 'serializers' && (SERIALIZERS & value).empty?
        add_error("Unsupported serializer: #{value}")
      end
      
      if attr == 'type' && TYPES.exclude?(value)
        add_error("Unsupported type: #{value}")
      end
      
      if attr == 'name' && value.length < 3
        add_error("Field name is too short")
      end
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