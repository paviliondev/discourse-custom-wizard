class CustomWizard::Api::Endpoint
  include ActiveModel::SerializerSupport

  attr_accessor :id,
                :method,
                :url

  def initialize(service, params)
    @service = service
    data = params.is_a?(String) ? ::JSON.parse(params) : params

    data.each do |k, v|
      self.send "#{k}=", v if self.respond_to?(k)
    end
  end

  def self.set(service, data)
    model = data[:endpoint_id] ? self.get(service, data[:endpoint_id]) : {}
    endpoint_id = model[:endpoint_id] || SecureRandom.hex(8)

    data.each do |k, v|
      model.send "#{k}=", v if model.respond_to?(k)
    end

    PluginStore.set("custom_wizard_api_#{service}", "endpoint_#{endpoint_id}", model.as_json)

    self.get(service)
  end

  def self.get(service, endpoint_id)
    return nil if !endpoint_id
    data = PluginStore.get("custom_wizard_api_#{service}", "endpoint_#{endpoint_id}")
    data[:id] = endpoint_id
    self.new(service, data)
  end

  def self.list
    PluginStoreRow.where("plugin_name LIKE 'custom_wizard_api_%' AND key LIKE 'endpoint_%'")
      .map do |record|
        service = record['plugin_name'].split('_').last
        data = ::JSON.parse(record['value'])
        data[:id] = record['key'].split('_').last
        self.new(service, data)
      end
  end
end
