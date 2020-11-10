# frozen_string_literal: true

class ::CustomWizard::CustomField
  include HasErrors
  include ActiveModel::Serialization
  
  attr_reader :id
  
  ATTRS ||= ["name", "klass", "type", "serializers"]
  REQUIRED ||= ["name", "klass", "type"]
  NAMESPACE ||= "custom_wizard_custom_fields"
  NAME_MIN_LENGTH ||= 3
  
  CLASSES ||= {
    topic: ["topic_view", "topic_list_item"],
    group: ["basic_group"],
    category: ["basic_category"],
    post: ["post"]
  }
  TYPES ||= ["string", "boolean", "integer", "json"]
  
  def self.serializers
    CLASSES.values.flatten.uniq
  end
  
  def initialize(id, data)
    @id = id
    data = data.with_indifferent_access
    
    ATTRS.each do |attr|
      self.class.class_eval { attr_accessor attr }
      
      value = data[attr]
      
      if value.present?
        send("#{attr}=", value)
      end
    end
  end

  def save
    validate

    if valid?
      data = {}
      key = name
      
      (ATTRS - ['name']).each do |attr|
        data[attr] = send(attr)
      end
      
      if self.class.save_to_store(id, key, data)
        self.class.invalidate_cache
        true
      else
        false
      end
    else
      false
    end
  end
  
  def validate
    ATTRS.each do |attr|
      value = send(attr)
      i18n_key = "wizard.custom_field.error"
      
      if value.blank?
        if REQUIRED.include?(attr)
          add_error(I18n.t("#{i18n_key}.required_attribute", attr: attr))
        end
        next
      end
      
      if (attr == 'klass' && CLASSES.keys.exclude?(value.to_sym)) ||
         (attr == 'serializers' && CLASSES[klass.to_sym].blank?)
        add_error(I18n.t("#{i18n_key}.unsupported_class", class: value))
        next
      end
      
      if attr == 'serializers' && (unsupported = value - CLASSES[klass.to_sym]).length > 0
        add_error(I18n.t("#{i18n_key}.unsupported_serializers",
          class: klass,
          serializers: unsupported.join(", ")
        ))
      end
      
      if attr == 'type' && TYPES.exclude?(value)
        add_error(I18n.t("#{i18n_key}.unsupported_type", type: value))
      end
      
      
      if attr == 'name'
        unless value.is_a?(String)
          add_error(I18n.t("#{i18n_key}.name_invalid", name: value))
        end
        
        if value.length < NAME_MIN_LENGTH
          add_error(I18n.t("#{i18n_key}.name_too_short", name: value, min_length: NAME_MIN_LENGTH))
        end
      
        if new? && self.class.exists?(name)
          add_error(I18n.t("#{i18n_key}.name_already_taken", name: value))
        end
        
        begin
          @name = value.parameterize(separator: '_')
        rescue
          add_error(I18n.t("#{i18n_key}.name_invalid", name: value))
        end
      end
    end
  end
  
  def new?
    id.blank?
  end
  
  def valid?
    errors.blank?
  end
  
  def self.reset
    @list = nil
  end
  
  def self.list
    @list ||= PluginStoreRow.where(plugin_name: NAMESPACE)
      .map { |record| create_from_store(record) }
  end
  
  def self.list_by(attr, value)
    self.list.select do |cf|
      if attr == :serializers
        cf.send(attr).include?(value)
      else
        cf.send(attr) == value
      end
    end
  end
  
  def self.exists?(name)
    PluginStoreRow.where(plugin_name: NAMESPACE, key: name).exists?
  end
  
  def self.find(field_id)
    record = PluginStoreRow.find_by(id: field_id, plugin_name: NAMESPACE)
    
    if record
      create_from_store(record)
    else
      false
    end
  end
  
  def self.find_by_name(name)
    record = PluginStoreRow.find_by(key: name, plugin_name: NAMESPACE)
    
    if record
      create_from_store(record)
    else
      false
    end
  end
  
  def self.create_from_store(record)
    data = JSON.parse(record.value)
    data[:name] = record.key
    new(record.id, data)
  end
  
  def self.save_to_store(id = nil, key, data)    
    if id
      record = PluginStoreRow.find_by(id: id, plugin_name: NAMESPACE)
      return false if !record
      record.key = key
      record.value = data.to_json
      record.save
    else
      record = PluginStoreRow.new(plugin_name: NAMESPACE, key: key)
      record.type_name = "JSON"
      record.value = data.to_json
      record.save
    end
  end
  
  def self.destroy(name)
    if exists?(name)
      PluginStoreRow.where(plugin_name: NAMESPACE, key: name).destroy_all
      invalidate_cache
      true
    else
      false
    end
  end
  
  def self.invalidate_cache
    self.reset
    Discourse.clear_readonly!
    Discourse.request_refresh!
  end
end