# frozen_string_literal: true

class CustomWizard::Notice::ConnectionError

  attr_reader :type_key

  def initialize(type_key)
    @type_key = type_key
  end

  def create!
    id = "#{type_key.to_s}_error"

    if attrs = PluginStore.get(namespace, id)
      attrs['updated_at'] = Time.now
      attrs['count'] = attrs['count'].to_i + 1
    else
      domain = CustomWizard::Notice.send("#{type_key.to_s}_domain")
      attrs = {
        message: I18n.t("wizard.notice.connection_error", domain: domain),
        type: self.class.types[type_key],
        created_at: Time.now,
        count: 1
      }
    end

    PluginStore.set(namespace, id, attrs)
    @errors = nil
  end

  def expire!
    if errors.exists?
      errors.each do |error_row|
        error = JSON.parse(error_row.value)
        error['expired_at'] = Time.now
        error_row.value = error.to_json
        error_row.save
      end
    end
  end

  def self.types
    @types ||= Enum.new(
      plugin_status: 0,
      subscription_messages: 1
    )
  end

  def plugin_status_limit
    5
  end

  def subscription_messages_limit
    10
  end

  def limit
    self.send("#{type_key.to_s}_limit")
  end

  def reached_limit?
    return false unless errors.exists?
    current_error['count'].to_i >= limit
  end

  def current_error
    JSON.parse(errors.first.value)
  end

  def namespace
    "#{CustomWizard::PLUGIN_NAME}_notice_connection"
  end

  def errors
    @errors ||= begin
      query = PluginStoreRow.where(plugin_name: namespace)
      query = query.where("(value::json->>'type')::integer = ?", self.class.types[type_key])
      query.where("(value::json->>'expired_at') IS NULL")
    end
  end
end
