class CustomWizard::Api
  include ActiveModel::SerializerSupport

  attr_accessor :name,
                :title

  def initialize(name, data={})
    @name = name
    data.each do |k, v|
      self.send "#{k}=", v if self.respond_to?(k)
    end
  end

  def self.set(name, data)
    PluginStore.set("custom_wizard_api_#{name}", "metadata", data)
  end

  def self.get(name)
    if data = PluginStore.get("custom_wizard_api_#{name}", "metadata")
      self.new(name, data)
    end
  end

  def self.remove(name)
    PluginStore.remove("custom_wizard_api_#{name}", "metadata")
  end

  def self.list
    PluginStoreRow.where("plugin_name LIKE 'custom_wizard_api_%' AND key = 'metadata'")
      .map do |record|
        self.new(record['plugin_name'].sub("custom_wizard_api_", ""), ::JSON.parse(record['value']))
      end
  end
end
