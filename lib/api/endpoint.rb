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
    if new_data['id']
      data = self.get(api_name, new_data['id'], data_only: true)
      endpoint_id = new_data['id']
    else
      data = {}
      endpoint_id = SecureRandom.hex(3)
    end

    new_data.each do |k, v|
      data[k.to_sym] = v
    end

    PluginStore.set("custom_wizard_api_#{api_name}", "endpoint_#{endpoint_id}", data)

    self.get(api_name, endpoint_id)
  end

  def self.get(api_name, endpoint_id, opts={})
    return nil if !endpoint_id

    if data = PluginStore.get("custom_wizard_api_#{api_name}", "endpoint_#{endpoint_id}")
      if opts[:data_only]
        data
      else
        data[:id] = endpoint_id
        self.new(api_name, data)
      end
    else
      nil
    end
  end

  def self.remove(api_name)
    PluginStoreRow.where("plugin_name = 'custom_wizard_api_#{api_name}' AND key LIKE 'endpoint_%'").destroy_all
  end

  def self.list(api_name)
    PluginStoreRow.where("plugin_name LIKE 'custom_wizard_api_#{api_name}' AND key LIKE 'endpoint_%'")
      .map do |record|
        api_name = record['plugin_name'].sub("custom_wizard_api_", "")
        data = ::JSON.parse(record['value'])
        data[:id] = record['key'].split('_').last
        self.new(api_name, data)
      end
  end

  def self.request(user, api_name, endpoint_id, body)
    endpoint = self.get(api_name, endpoint_id)
    auth = CustomWizard::Api::Authorization.get_header_authorization_string(api_name)

    connection = Excon.new(
      URI.parse(URI.encode(endpoint.url)).to_s,
      :headers => {
        "Authorization" => auth,
        "Accept" => "application/json, */*",
        "Content-Type" => "application/json"
      }
    )

    params = {
      method: endpoint.method
    }

    if body
      body = JSON.generate(body)
      body.delete! '\\'
      params[:body] = body
    end

    begin
      response = connection.request(params)
      log_params = {time: Time.now, user_id: user.id, status: 'SUCCESS', url: endpoint.url, error: ""}

      CustomWizard::Api::LogEntry.set(api_name, log_params)
      return JSON.parse(response.body)
    rescue
      # TODO: improve error detail
      log_params = {time: Time.now, user_id: user.id, status: 'FAILURE', url: endpoint.url, error: "API request failed"}
      CustomWizard::Api::LogEntry.set(api_name, log_params)
      return JSON.parse "[{\"error\":\"API request failed\"}]"
    end
  end
end
