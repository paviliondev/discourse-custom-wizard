class CustomWizard::Api::Endpoint
  include ActiveModel::SerializerSupport

  attr_accessor :id,
                :name,
                :api_name,
                :method,
                :url

  def initialize(api_name, data={})
    @api_name = api_name

    data.each do |k, v|
      self.send "#{k}=", v if self.respond_to?(k)
    end
  end

  def self.set(api_name, new_data)
    data = new_data[:endpoint_id] ? self.get(api_name, new_data[:endpoint_id], data_only: true) : {}
    endpoint_id = new_data[:endpoint_id] || SecureRandom.hex(3)

    new_data.each do |k, v|
      data[k.to_sym] = v
    end

    PluginStore.set("custom_wizard_api_#{api_name}", "endpoint_#{endpoint_id}", data)

    self.get(api_name, endpoint_id)
  end

  def self.get(api_name, endpoint_id, opts={})
    return nil if !endpoint_id

    if data = PluginStore.get("custom_wizard_api_#{api_name}", "endpoint_#{endpoint_id}")
      data[:id] = endpoint_id

      if opts[:data_only]
        data
      else
        self.new(api_name, data)
      end
    else
      nil
    end
  end

  def self.remove(api_name)
    PluginStoreRow.where("plugin_name = 'custom_wizard_api_#{api_name}' AND key LIKE 'endpoint_%'").destroy_all
  end

  def self.list
    PluginStoreRow.where("plugin_name LIKE 'custom_wizard_api_%' AND key LIKE 'endpoint_%'")
      .map do |record|
        api_name = record['plugin_name'].sub("custom_wizard_api_", "")
        data = ::JSON.parse(record['value'])
        data[:id] = record['key'].split('_').last
        self.new(api_name, data)
      end
  end
end
