# frozen_string_literal: true

class CustomWizard::Notice
  include ActiveModel::Serialization

  PLUGIN_STATUS_DOMAINS = {
    "tests-passed" => "try.thepavilion.io",
    "stable" => "stable.try.thepavilion.io"
  }
  SUBSCRIPTION_MESSAGES_DOMAIN = "thepavilion.io"
  LOCALHOST_DOMAIN = "localhost:3000"
  PLUGIN_STATUSES_TO_WARN = %w(incompatible tests_failing)
  CHECK_PLUGIN_STATUS_ON_BRANCH = %w(tests-passed main stable)

  attr_reader :id,
              :message,
              :type,
              :created_at

  attr_accessor :retrieved_at,
                :updated_at,
                :dismissed_at,
                :expired_at

  def initialize(attrs)
    @id = Digest::SHA1.hexdigest(attrs[:message])
    @message = attrs[:message]
    @type = attrs[:type].to_i
    @created_at = attrs[:created_at]
    @updated_at = attrs[:updated_at]
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
      plugin_status_warning: 1,
      plugin_status_connection_error: 2,
      subscription_messages_connection_error: 3
    )
  end

  def self.update(skip_subscription: false, skip_plugin: false)
    notices = []

    if !skip_subscription
      subscription_messages = request(:subscription_messages)

      if subscription_messages.present?
        subscription_notices = convert_subscription_messages_to_notices(subscription_messages[:messages])
        notices.push(*subscription_notices)
      end
    end

    if !skip_plugin && request_plugin_status?
      plugin_status = request(:plugin_status)

      if plugin_status.present? && plugin_status[:status].present? && plugin_status[:status].is_a?(Hash)
        plugin_notice = convert_plugin_status_to_notice(plugin_status[:status])
        notices.push(plugin_notice) if plugin_notice
      end
    end

    notices.each do |notice_data|
      notice = new(notice_data)
      notice.retrieved_at = Time.now
      notice.save
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
        message: I18n.t('wizard.notice.compatibility_issue', domain: plugin_status_domain),
        type: types[:plugin_status_warning],
        created_at: plugin_status[:status_changed_at]
      }
    else
      expire_notices(types[:plugin_status_warning])
    end

    notice
  end

  def self.notify_connection_errors(connection_type_key)
    domain = self.send("#{connection_type_key.to_s}_domain")
    message = I18n.t("wizard.notice.#{connection_type_key.to_s}.connection_error_limit", domain: domain)
    notices = list(type: types[:connection_error], message: message)

    if notices.any?
      notice = notices.first
      notice.updated_at = Time.now
      notice.save
    else
      notice = new(
        message: message,
        type: types["#{connection_type_key}_connection_error".to_sym],
        created_at: Time.now
      )
      notice.save
    end
  end

  def self.expire_notices(type)
    list(type: type).each(&:expire)
  end

  def self.request_plugin_status?
    CHECK_PLUGIN_STATUS_ON_BRANCH.include?(Discourse.git_branch) || Rails.env.test? || Rails.env.development?
  end

  def self.subscription_messages_domain
    (Rails.env.test? || Rails.env.development?) ? LOCALHOST_DOMAIN : SUBSCRIPTION_MESSAGES_DOMAIN
  end

  def self.subscription_messages_url
    "http://#{subscription_messages_domain}/subscription-server/messages.json"
  end

  def self.plugin_status_domain
    return LOCALHOST_DOMAIN if (Rails.env.test? || Rails.env.development?)
    PLUGIN_STATUS_DOMAINS[Discourse.git_branch]
  end

  def self.plugin_status_url
    "http://#{plugin_status_domain}/plugin-manager/status/discourse-custom-wizard"
  end

  def self.request(type)
    url = self.send("#{type.to_s}_url")
    response = Excon.get(url)
    connection_error = CustomWizard::Notice::ConnectionError.new(type)

    if response.status == 200
      connection_error.expire!
      expire_notices(types["#{type}_connection_error".to_sym])

      begin
        data = JSON.parse(response.body).deep_symbolize_keys
      rescue JSON::ParserError
        return nil
      end

      data
    else
      connection_error.create!
      notify_connection_errors(type) if connection_error.reached_limit?

      nil
    end
  end

  def self.namespace
    "#{CustomWizard::PLUGIN_NAME}_notice"
  end

  def self.find(id)
    raw = PluginStore.get(namespace, id)
    new(raw.symbolize_keys) if raw.present?
  end

  def self.store(id, raw_notice)
    PluginStore.set(namespace, id, raw_notice)
  end

  def self.list_query(type: nil, message: nil, include_recently_expired: false)
    query = PluginStoreRow.where(plugin_name: namespace)
    query = query.where("(value::json->>'expired_at') IS NULL#{include_recently_expired ? " OR (value::json->>'expired_at')::date > now()::date - 1" : ""}")
    query = query.where("(value::json->>'type')::integer = ?", type) if type
    query = query.where("(value::json->>'message')::text = ?", message) if message
    query.order("value::json->>'created_at' DESC")
  end

  def self.list(type: nil, message: nil, include_recently_expired: false)
    list_query(type: type, message: message, include_recently_expired: include_recently_expired)
      .map { |r| self.new(JSON.parse(r.value).symbolize_keys) }
  end
end
