class CustomWizard::Api::LogEntry
  include ActiveModel::SerializerSupport

  attr_accessor :log_id,
                :time,
                :user_id,
                :status,
                :url,
                :error,
                :username,
                :userpath,
                :name,
                :avatar_template

  def initialize(api_name, data={})
    @api_name = api_name

    data.each do |k, v|
      self.send "#{k}=", v if self.respond_to?(k)
    end
  end

  def self.set(api_name, new_data)
    if new_data['log_id']
      data = self.get(api_name, new_data['log_id'], data_only: true)
      log_id = new_data['log_id']
    else
      data = {}
      log_id = SecureRandom.hex(3)
    end

    new_data.each do |k, v|
      data[k.to_sym] = v
    end

    PluginStore.set("custom_wizard_api_#{api_name}", "log_#{log_id}", data)

    self.get(api_name, log_id)
  end

  def self.get(api_name, log_id, opts={})
    return nil if !log_id

    if data = PluginStore.get("custom_wizard_api_#{api_name}", "log_#{log_id}")
      if opts[:data_only]
        data
      else
        data[:log_id] = log_id
        self.new(api_name, data)
      end
    else
      nil
    end
  end

  def self.remove(api_name)
    PluginStoreRow.where("plugin_name = 'custom_wizard_api_#{api_name}' AND key LIKE 'log_%'").destroy_all
  end

  def self.list(api_name)
    PluginStoreRow.where("plugin_name LIKE 'custom_wizard_api_#{api_name}' AND key LIKE 'log_%'")
      .map do |record|
        api_name = record['plugin_name'].sub("custom_wizard_api_", "")
        data = ::JSON.parse(record['value'])
        data[:log_id] = record['key'].split('_').last
        this_user = User.find_by(id: data['user_id'])
        unless this_user.nil?
          data[:user_id] = this_user.id || nil
          data[:username] = this_user.username || ""
          data[:userpath] = "/u/#{this_user.username_lower}/activity"
          data[:name] = this_user.name || ""
          data[:avatar_template] = "/user_avatar/default/#{this_user.username_lower}/97/#{this_user.uploaded_avatar_id}.png"
        else
          data[:user_id] = nil
          data[:username] = ""
          data[:userpath] = ""
          data[:name] = ""
          data[:avatar_template] = ""
        end
        self.new(api_name, data)
      end
  end

  def self.clear(api_name)
    PluginStoreRow.where("plugin_name = 'custom_wizard_api_#{api_name}' AND key LIKE 'log_%'").destroy_all
  end

end
