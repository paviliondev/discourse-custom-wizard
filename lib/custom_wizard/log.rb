# frozen_string_literal: true
class CustomWizard::Log
  include ActiveModel::Serialization

  attr_reader :date, :wizard_id, :action, :username, :message
  attr_accessor :user

  PAGE_LIMIT = 100

  def initialize(attrs)
    @date = attrs['date']
    @action = attrs['action']
    @message = attrs['message']
    @wizard_id = attrs['wizard_id']
    @username = attrs['username']
  end

  def self.create(wizard_id, action, username, message)
    log_id = SecureRandom.hex(12)

    PluginStore.set('custom_wizard_log',
      log_id.to_s,
      {
        date: Time.now,
        wizard_id: wizard_id,
        action: action,
        username: username,
        message: message
      }
    )
  end

  def self.list_query(wizard_id = nil)
    query = PluginStoreRow.where("plugin_name = 'custom_wizard_log' AND (value::json->'date') IS NOT NULL")
    query = query.where("(value::json->>'wizard_id') = ?", wizard_id) if wizard_id
    query.order("value::json->>'date' DESC")
  end

  def self.list(page = 0, limit = nil, wizard_id = nil)
    limit = limit.to_i > 0 ? limit.to_i : PAGE_LIMIT
    page = page.to_i
    logs = self.list_query(wizard_id)

    result = OpenStruct.new(logs: [], total: nil)
    result.total = logs.size
    result.logs = logs.limit(limit)
      .offset(page * limit)
      .map { |r| self.new(JSON.parse(r.value)) }

    result
  end
end
