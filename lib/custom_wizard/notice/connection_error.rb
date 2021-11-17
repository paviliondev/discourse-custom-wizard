# frozen_string_literal: true

class CustomWizard::Notice::ConnectionError

  attr_reader :archetype

  def initialize(archetype)
    @archetype = archetype
  end

  def create!
    if attrs = current_error
      key = "#{archetype.to_s}_error_#{attrs[:id]}"
      attrs[:updated_at] = Time.now
      attrs[:count] = attrs[:count].to_i + 1
    else
      domain = CustomWizard::Notice.send("#{archetype.to_s}_domain")
      id = SecureRandom.hex(8)
      attrs = {
        id: id,
        message: I18n.t("wizard.notice.connection_error", domain: domain),
        archetype: CustomWizard::Notice.archetypes[archetype.to_sym],
        created_at: Time.now,
        count: 1
      }
      key = "#{archetype.to_s}_error_#{id}"
    end

    PluginStore.set(namespace, key, attrs)

    @current_error = nil
  end

  def expire!
    if query = current_error(query_only: true)
      record = query.first
      error = JSON.parse(record.value)
      error['expired_at'] = Time.now
      record.value = error.to_json
      record.save
    end
  end

  def plugin_status_limit
    5
  end

  def subscription_message_limit
    10
  end

  def limit
    self.send("#{archetype.to_s}_limit")
  end

  def reached_limit?
    return false unless current_error.present?
    current_error[:count].to_i >= limit
  end

  def namespace
    "#{CustomWizard::PLUGIN_NAME}_notice_connection"
  end

  def current_error(query_only: false)
    @current_error ||= begin
      query = PluginStoreRow.where(plugin_name: namespace)
      query = query.where("(value::json->>'archetype')::integer = ?", CustomWizard::Notice.archetypes[archetype.to_sym])
      query = query.where("(value::json->>'expired_at') IS NULL")

      return nil if !query.exists?
      return query if query_only

      JSON.parse(query.first.value).deep_symbolize_keys
    end
  end
end
