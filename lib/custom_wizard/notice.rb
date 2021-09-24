# frozen_string_literal: true

class CustomWizard::Notice
  include ActiveModel::Serialization

  PLUGIN_STATUSES_TO_WARN = %w(incompatible tests_failing)

  attr_reader :id,
              :message,
              :type,
              :created_at

  attr_accessor :retrieved_at,
                :dismissed_at,
                :expired_at

  def initialize(attrs)
    @id = Digest::SHA1.hexdigest(attrs[:message])
    @message = attrs[:message]
    @type = attrs[:type].to_i
    @created_at = attrs[:created_at]
    @retrieved_at = attrs[:retrieved_at]
    @dismissed_at = attrs[:dismissed_at]
    @expired_at = attrs[:expired_at]
  end

  def dismiss
    if dismissable?
      self.dismissed_at = Time.now
      self.save
    end
  end

  def expire
    self.expired_at = Time.now
    self.save
  end

  def expired?
    expired_at.present?
  end

  def dismissed?
    dismissed_at.present?
  end

  def dismissable?
    true
  end

  def save
    attrs = {
      expired_at: expired_at,
      created_at: created_at,
      expired_at: expired_at,
      message: message,
      type: type
    }

    if current = self.class.find(self.id)
      attrs[:dismissed_at] = current.dismissed_at || self.dismissed_at
    end

    self.class.store(id, attrs)
  end

  def self.types
    @types ||= Enum.new(
      info: 0,
      warning: 1
    )
  end

  def self.connection_types
    @connection_types ||= Enum.new(
      plugin_status: 0,
      subscription: 1
    )
  end

  def self.update(skip_subscription: false, skip_plugin: false)
    notices = []

    if !skip_subscription
      subscription_messages = request(subscription_messages_url)
      if subscription_messages.present?
        subscription_notices = convert_subscription_messages_to_notices(subscription_messages[:messages])
        notices.push(*subscription_notices)
      end
    end

    if !skip_plugin && (Discourse.git_branch === 'tests-passed' || (Rails.env.test? || Rails.env.development?))
      plugin_status = request(plugin_status_url)

      if plugin_status.present? && plugin_status[:status].present? && plugin_status[:status].is_a?(Hash)
        plugin_notice = convert_plugin_status_to_notice(plugin_status[:status])
        notices.push(plugin_notice) if plugin_notice

        expire_connection_errors(connection_types[:plugin_status])
      else
        create_connection_error(connection_types[:plugin_status])
      end
    end

    notices.each do |notice_data|
      notice = new(notice_data)
      notice.retrieved_at = Time.now
      notice.save
    end

    if reached_connection_error_limit(connection_types[:plugin_status])
      new(
        message: I18n.t("wizard.notice.plugin_status_connection_error_limit"),
        type: types[:warning],
        created_at: Time.now
      )
    end
  end

  def self.convert_subscription_messages_to_notices(messages)
    messages.map do |message|
      {
        message: message[:message],
        type: types[message[:type].to_sym],
        created_at: message[:created_at],
        expired_at: message[:expired_at]
      }
    end
  end

  def self.convert_plugin_status_to_notice(plugin_status)
    notice = nil

    if PLUGIN_STATUSES_TO_WARN.include?(plugin_status[:status])
      notice = {
        message: PrettyText.cook(I18n.t('wizard.notice.compatibility_issue', server: plugin_status_domain)),
        type: types[:warning],
        created_at: plugin_status[:status_changed_at]
      }
    else
      list(types[:warning]).each(&:expire)
    end

    notice
  end

  def self.subscription_messages_domain
    "localhost:3000"
  end

  def self.subscription_messages_url
    "http://#{subscription_messages_domain}/subscription-server/messages.json"
  end

  def self.plugin_status_domain
    "localhost:4200"
  end

  def self.plugin_status_url
    "http://#{plugin_status_domain}/plugin-manager/status/discourse-custom-wizard"
  end
  
  def self.request(url)
    response = Excon.get(url)

    if response.status == 200
      begin
        data = JSON.parse(response.body).deep_symbolize_keys
      rescue JSON::ParserError
        return nil
      end
      
      data
    else
      nil
    end
  end

  def self.namespace
    "#{CustomWizard::PLUGIN_NAME}_notice"
  end

  def self.namespace_connection
    "#{CustomWizard::PLUGIN_NAME}_notice_connection"
  end

  def self.find(id)
    raw = PluginStore.get(namespace, id)
    new(raw.symbolize_keys) if raw.present?
  end

  def self.store(id, raw_notice)
    PluginStore.set(namespace, id, raw_notice)
  end

  def self.plugin_status_connection_error_limit
    5
  end

  def self.list_connection_query(type)
    query = PluginStoreRow.where(plugin_name: namespace_connection)
    query.where("(value::json->>'type')::integer = ?", type)
  end

  def self.expire_connection_errors(type)
    list_connection_query(type).update_all("value = jsonb_set(value::jsonb, '{ expired_at }', (to_char(current_timestamp, 'HH12:MI:SS'))::jsonb)")
  end

  def self.create_connection_error(type)
    id = SecureRandom.hex(16)
    attrs = {
      message: I18n.t("wizard.notice.connection_error", domain: self.send("#{type}_domain")),
      type: type,
      created_at: Time.now
    }
    PluginStore.set(namespace_connection, id, attrs)
  end

  def self.reached_connection_error_limit(type)
    list_connection_query(type).size >= self.send("#{connection_types.key(type)}_connection_error_limit")
  end

  def self.list_query(type = nil)
    query = PluginStoreRow.where(plugin_name: namespace)
    query = query.where("(value::json->>'expired_at') IS NULL OR (value::json->>'expired_at')::date > now()::date - 1")
    query = query.where("(value::json->>'type')::integer = ?", type) if type
    query.order("value::json->>'created_at' DESC")
  end

  def self.list(type = nil)
    list_query(type)
      .map { |r| self.new(JSON.parse(r.value).symbolize_keys) }
  end
end
