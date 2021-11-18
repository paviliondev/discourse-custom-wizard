# frozen_string_literal: true

class CustomWizard::Notice
  include ActiveModel::Serialization

  PLUGIN_STATUS_DOMAINS = {
    "main" => "plugins.discourse.pavilion.tech",
    "master" => "plugins.discourse.pavilion.tech",
    "tests-passed" => "plugins.discourse.pavilion.tech",
    "stable" => "stable.plugins.discourse.pavilion.tech"
  }
  SUBSCRIPTION_MESSAGE_DOMAIN = "test.thepavilion.io"
  LOCALHOST_DOMAIN = "localhost:3000"
  PLUGIN_STATUSES_TO_WARN = %w(incompatible tests_failing)
  CHECK_PLUGIN_STATUS_ON_BRANCH = %w(tests-passed main stable)
  PAGE_LIMIT = 30

  attr_reader :id,
              :title,
              :message,
              :type,
              :archetype,
              :created_at

  attr_accessor :retrieved_at,
                :updated_at,
                :dismissed_at,
                :expired_at,
                :hidden_at

  def initialize(attrs)
    @id = self.class.generate_notice_id(attrs[:title], attrs[:created_at])
    @title = attrs[:title]
    @message = attrs[:message]
    @type = attrs[:type].to_i
    @archetype = attrs[:archetype].to_i
    @created_at = attrs[:created_at]
    @updated_at = attrs[:updated_at]
    @retrieved_at = attrs[:retrieved_at]
    @dismissed_at = attrs[:dismissed_at]
    @expired_at = attrs[:expired_at]
    @hidden_at = attrs[:hidden_at]
  end

  def dismiss!
    if dismissable?
      self.dismissed_at = DateTime.now.iso8601(3)
      self.save_and_publish
    end
  end

  def hide!
    if can_hide?
      self.hidden_at = DateTime.now.iso8601(3)
      self.save_and_publish
    end
  end

  def expire!
    if !expired?
      self.expired_at = DateTime.now.iso8601(3)
      self.save_and_publish
    end
  end

  def save_and_publish
    if self.save
      self.class.publish_notice_count
      true
    else
      false
    end
  end

  def expired?
    expired_at.present?
  end

  def dismissed?
    dismissed_at.present?
  end

  def dismissable?
    !expired? && !dismissed? && type === self.class.types[:info]
  end

  def hidden?
    hidden_at.present?
  end

  def can_hide?
    !hidden? && (
      type === self.class.types[:connection_error] ||
      type === self.class.types[:warning]
    ) && (
      archetype === self.class.archetypes[:plugin_status]
    )
  end

  def save
    attrs = {
      expired_at: expired_at,
      updated_at: updated_at,
      retrieved_at: retrieved_at,
      created_at: created_at,
      title: title,
      message: message,
      type: type,
      archetype: archetype
    }

    if current = self.class.find(self.id)
      attrs[:dismissed_at] = current.dismissed_at || self.dismissed_at
      attrs[:hidden_at] = current.hidden_at || self.hidden_at
    end

    self.class.store(id, attrs)
  end

  def self.types
    @types ||= Enum.new(
      info: 0,
      warning: 1,
      connection_error: 2
    )
  end

  def self.archetypes
    @archetypes ||= Enum.new(
      subscription_message: 0,
      plugin_status: 1
    )
  end

  def self.update(skip_subscription: false, skip_plugin: false)
    notices = []

    if !skip_subscription
      subscription_messages = request(:subscription_message)

      if subscription_messages.present?
        subscription_notices = convert_subscription_messages_to_notices(subscription_messages[:messages])
        notices.push(*subscription_notices)
      end
    end

    if !skip_plugin && request_plugin_status?
      plugin_status = request(:plugin_status)

      if plugin_status.present? && plugin_status[:status].present?
        plugin_notice = convert_plugin_status_to_notice(plugin_status)
        notices.push(plugin_notice) if plugin_notice
      end
    end

    if notices.any?
      notices.each do |notice_data|
        notice = new(notice_data)
        notice.retrieved_at = DateTime.now.iso8601(3)
        notice.save
      end

      publish_notice_count
    end
  end

  def self.publish_notice_count
    payload = {
      active_notice_count: CustomWizard::Notice.active_count
    }
    MessageBus.publish("/custom-wizard/notices", payload, group_ids: [Group::AUTO_GROUPS[:admins]])
  end

  def self.convert_subscription_messages_to_notices(messages)
    messages.reduce([]) do |result, message|
      id = generate_notice_id(message[:title], message[:created_at])
      result.push(
        id: id,
        title: message[:title],
        message: message[:message],
        type: types[message[:type].to_sym],
        archetype: archetypes[:subscription_message],
        created_at: message[:created_at],
        expired_at: message[:expired_at]
      )
      result
    end
  end

  def self.convert_plugin_status_to_notice(plugin_status)
    notice = nil

    if PLUGIN_STATUSES_TO_WARN.include?(plugin_status[:status])
      title = I18n.t('wizard.notice.compatibility_issue.title')
      created_at = plugin_status[:status_changed_at]
      id = generate_notice_id(title, created_at)

      unless exists?(id)
        message = I18n.t('wizard.notice.compatibility_issue.message', domain: plugin_status_domain)
        notice = {
          id: id,
          title: title,
          message: message,
          type: types[:warning],
          archetype: archetypes[:plugin_status],
          created_at: created_at
        }
      end
    else
      expire_all(types[:warning], archetypes[:plugin_status])
    end

    notice
  end

  def self.notify_connection_errors(archetype)
    domain = self.send("#{archetype.to_s}_domain")
    title = I18n.t("wizard.notice.#{archetype.to_s}.connection_error.title")
    notices = list(type: types[:connection_error], archetype: archetypes[archetype.to_sym], title: title)

    if notices.any?
      notice = notices.first
      notice.updated_at = DateTime.now.iso8601(3)
      notice.save
    else
      notice = new(
        title: title,
        message: I18n.t("wizard.notice.#{archetype.to_s}.connection_error.message", domain: domain),
        archetype: archetypes[archetype.to_sym],
        type: types[:connection_error],
        created_at: DateTime.now.iso8601(3),
        updated_at: DateTime.now.iso8601(3)
      )
      notice.save
    end

    publish_notice_count
  end

  def self.request_plugin_status?
    CHECK_PLUGIN_STATUS_ON_BRANCH.include?(Discourse.git_branch) || Rails.env.test? || Rails.env.development?
  end

  def self.subscription_message_domain
    return LOCALHOST_DOMAIN if (Rails.env.test? || Rails.env.development?)
    SUBSCRIPTION_MESSAGE_DOMAIN
  end

  def self.subscription_message_url
    "http://#{subscription_message_domain}/subscription-server/messages.json"
  end

  def self.plugin_status_domain
    return LOCALHOST_DOMAIN if (Rails.env.test? || Rails.env.development?)
    PLUGIN_STATUS_DOMAINS[Discourse.git_branch]
  end

  def self.plugin_status_url
    "http://#{plugin_status_domain}/plugin-manager/status/discourse-custom-wizard"
  end

  def self.request(archetype)
    url = self.send("#{archetype.to_s}_url")

    begin
      response = Excon.get(url)
    rescue Excon::Error::Socket, Excon::Error::Timeout => e
      response = nil
    end
    connection_error = CustomWizard::Notice::ConnectionError.new(archetype)

    if response && response.status == 200
      connection_error.expire!
      expire_all(types[:connection_error], archetypes[archetype.to_sym])

      begin
        data = JSON.parse(response.body).deep_symbolize_keys
      rescue JSON::ParserError
        return nil
      end

      data
    else
      connection_error.create!
      notify_connection_errors(archetype) if connection_error.reached_limit?
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

  def self.exists?(id)
    PluginStoreRow.where(plugin_name: namespace, key: id).exists?
  end

  def self.store(id, raw_notice)
    PluginStore.set(namespace, id, raw_notice)
  end

  def self.list_query(type: nil, archetype: nil, title: nil, include_all: false, page: nil, visible: false)
    query = PluginStoreRow.where(plugin_name: namespace)
    query = query.where("(value::json->>'hidden_at') IS NULL") if visible
    query = query.where("(value::json->>'dismissed_at') IS NULL") unless include_all
    query = query.where("(value::json->>'expired_at') IS NULL") unless include_all
    query = query.where("(value::json->>'archetype')::integer = ?", archetype) if archetype
    if type
      type_query_str = type.is_a?(Array) ? "(value::json->>'type')::integer IN (?)" : "(value::json->>'type')::integer = ?"
      query = query.where(type_query_str, type)
    end
    query = query.where("(value::json->>'title')::text = ?", title) if title
    query = query.limit(PAGE_LIMIT).offset(page.to_i * PAGE_LIMIT) if !page.nil?
    query.order("value::json->>'expired_at' DESC, value::json->>'updated_at' DESC,value::json->>'dismissed_at' DESC, value::json->>'created_at' DESC")
  end

  def self.list(type: nil, archetype: nil, title: nil, include_all: false, page: 0, visible: false)
    list_query(type: type, archetype: archetype, title: title, include_all: include_all, page: page, visible: visible)
      .map { |r| self.new(JSON.parse(r.value).symbolize_keys) }
  end

  def self.active_count
    list_query.count
  end

  def self.dismiss_all
    dismissed_count = PluginStoreRow.where("
      plugin_name = '#{namespace}' AND
      (value::json->>'type')::integer = #{types[:info]} AND
      (value::json->>'expired_at') IS NULL AND
      (value::json->>'dismissed_at') IS NULL
    ").update_all("
      value = jsonb_set(value::jsonb, '{dismissed_at}', (to_json(now())::text)::jsonb, true)
    ")
    publish_notice_count if dismissed_count.to_i > 0
    dismissed_count
  end

  def self.expire_all(type, archetype)
    expired_count = PluginStoreRow.where("
      plugin_name = '#{namespace}' AND
      (value::json->>'type')::integer = #{type} AND
      (value::json->>'archetype')::integer = #{archetype} AND
      (value::json->>'expired_at') IS NULL
    ").update_all("
      value = jsonb_set(value::jsonb, '{expired_at}', (to_json(now())::text)::jsonb, true)
    ")
    publish_notice_count if expired_count.to_i > 0
    expired_count
  end

  def self.generate_notice_id(title, created_at)
    Digest::SHA1.hexdigest("#{title}-#{created_at}")
  end
end
