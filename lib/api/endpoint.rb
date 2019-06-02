class CustomWizard::Api::Endpoint
  include ActiveModel::SerializerSupport

  attr_accessor :id,
                :method,
                :url

  def initialize(name, params)
    @name = name
    if data = params.is_a?(String) ? ::JSON.parse(params) : params
      data.each do |k, v|
        self.send "#{k}=", v if self.respond_to?(k)
      end
    end
  end

  def self.set(name, data)
    model = data[:endpoint_id] ? self.get(name, data[:endpoint_id]) : {}
    endpoint_id = model[:endpoint_id] || SecureRandom.hex(8)

    data.each do |k, v|
      model.send "#{k}=", v if model.respond_to?(k)
    end

    PluginStore.set("custom_wizard_api_#{name}", "endpoint_#{endpoint_id}", model.as_json)

    self.get(name)
  end

  def self.get(name, endpoint_id)
    return nil if !endpoint_id
    data = PluginStore.get("custom_wizard_api_#{name}", "endpoint_#{endpoint_id}")
    data[:id] = endpoint_id
    self.new(name, data)
  end

  def self.remove(name)
    PluginStoreRow.where("plugin_name = 'custom_wizard_api_#{name}' AND key LIKE 'endpoint_%'").destroy_all
  end

  def self.list
    PluginStoreRow.where("plugin_name LIKE 'custom_wizard_api_%' AND key LIKE 'endpoint_%'")
      .map do |record|
        name = record['plugin_name'].sub("custom_wizard_api_", "")
        data = ::JSON.parse(record['value'])
        data[:id] = record['key'].split('_').last
        self.new(name, data)
      end
  end
end
