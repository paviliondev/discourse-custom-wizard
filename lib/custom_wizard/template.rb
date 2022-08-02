# frozen_string_literal: true

class CustomWizard::Template
  include HasErrors

  AFTER_SIGNUP_CACHE_KEY ||= "after_signup_wizard_ids"
  AFTER_TIME_CACHE_KEY ||= "after_time_wizard_ids"

  attr_reader :data,
              :opts,
              :steps,
              :actions

  def initialize(data)
    @data = data
    @steps = data['steps'] || []
    @actions = data['actions'] || []
  end

  def save(opts = {})
    @opts = opts

    normalize_data
    validate_data
    prepare_data

    return false if errors.any?

    ActiveRecord::Base.transaction do
      schedule_save_jobs unless opts[:skip_jobs]
      PluginStore.set(CustomWizard::PLUGIN_NAME, @data[:id], @data)
      ensure_wizard_upload_references!
    end

    self.class.clear_cache_keys

    @data[:id]
  end

  def self.save(data, opts = {})
    new(data).save(opts)
  end

  def self.create(wizard_id)
    if data = find(wizard_id)
      new(data)
    else
      nil
    end
  end

  def self.find(wizard_id)
    PluginStore.get(CustomWizard::PLUGIN_NAME, wizard_id)
  end

  def self.find_record(wizard_id)
    PluginStoreRow.find_by(plugin_name: CustomWizard::PLUGIN_NAME, key: wizard_id)
  end

  def self.remove(wizard_id)
    wizard = CustomWizard::Wizard.create(wizard_id)
    return false if !wizard

    ActiveRecord::Base.transaction do
      ensure_wizard_upload_references!(wizard_id)
      PluginStore.remove(CustomWizard::PLUGIN_NAME, wizard.id)
      clear_user_wizard_redirect(wizard_id, after_time: !!wizard.after_time)
    end

    clear_cache_keys

    true
  end

  def self.exists?(wizard_id)
    PluginStoreRow.exists?(plugin_name: 'custom_wizard', key: wizard_id)
  end

  def self.list(setting: nil, query_str: nil, order: :id)
    query = "plugin_name = 'custom_wizard'"
    query += " AND (value::json ->> '#{setting}')::boolean IS TRUE" if setting
    query += " #{query_str}" if query_str

    PluginStoreRow.where(query).order(order)
      .reduce([]) do |result, record|
        attrs = JSON.parse(record.value)

        if attrs.present? &&
          attrs.is_a?(Hash) &&
          attrs['id'].present? &&
          attrs['name'].present?

          result.push(attrs)
        end

        result
      end
  end

  def self.clear_user_wizard_redirect(wizard_id, after_time: false)
    UserCustomField.where(name: 'redirect_to_wizard', value: wizard_id).destroy_all

    if after_time
      Jobs.cancel_scheduled_job(:set_after_time_wizard, wizard_id: wizard_id)
    end
  end

  def self.after_signup_ids
    ::CustomWizard::Cache.wrap(AFTER_SIGNUP_CACHE_KEY) do
      list(setting: 'after_signup').map { |t| t['id'] }
    end
  end

  def self.after_time_ids
    ::CustomWizard::Cache.wrap(AFTER_TIME_CACHE_KEY) do
      list(
        setting: 'after_time',
        query_str: "AND (value::json ->> 'after_time_scheduled')::timestamp < CURRENT_TIMESTAMP"
      ).map { |t| t['id'] }
    end
  end

  def self.can_redirect_users?(wizard_id)
    after_signup_ids.include?(wizard_id) || after_time_ids.include?(wizard_id)
  end

  def self.clear_cache_keys
    CustomWizard::Cache.new(AFTER_SIGNUP_CACHE_KEY).delete
    CustomWizard::Cache.new(AFTER_TIME_CACHE_KEY).delete
  end

  def self.ensure_wizard_upload_references!(wizard_id, wizard_upload_ids = [])
    wizard_record = find_record(wizard_id)

    if wizard_record
      UploadReference.ensure_exist!(
        upload_ids: wizard_upload_ids,
        target_type: "PluginStoreRow",
        target_id: wizard_record.id
      )
    end
  end

  private

  def normalize_data
    @data = ::JSON.parse(@data) if @data.is_a?(String)
    @data = @data.with_indifferent_access
  end

  def prepare_data
    @data[:steps].each do |step|
      if step[:raw_description]
        step[:description] = step[:raw_description]
      end

      remove_non_mapped_index(step)

      step[:fields].each do |field|
        remove_non_mapped_index(field)
      end
    end
  end

  def validate_data
    validator = CustomWizard::TemplateValidator.new(@data, @opts)
    validator.perform
    add_errors_from(validator)
  end

  def schedule_save_jobs
    if @data[:after_time] && @data[:after_time_scheduled]
      wizard_id = @data[:id]
      old_data = CustomWizard::Template.find(data[:id])

      begin
        enqueue_wizard_at = Time.parse(@data[:after_time_scheduled]).utc
      rescue ArgumentError
        errors.add :validation, I18n.t("wizard.validation.after_time")
        raise ActiveRecord::Rollback.new
      end

      if enqueue_wizard_at
        Jobs.cancel_scheduled_job(:set_after_time_wizard, wizard_id: wizard_id)
        Jobs.enqueue_at(enqueue_wizard_at, :set_after_time_wizard, wizard_id: wizard_id)
      elsif old_data && old_data[:after_time]
        clear_user_wizard_redirect(wizard_id, after_time: true)
      end
    end
  end

  def remove_non_mapped_index(object)
    if !object[:index].is_a?(Array)
      object.delete(:index)
    end
  end

  def ensure_wizard_upload_references!
    upload_ids = []

    @data[:steps].each do |step|
      upload_ids << step[:banner_upload_id] if step[:banner_upload_id]

      step[:fields].each do |field|
        upload_ids << field[:image_upload_id] if field[:image_upload_id]
      end
    end

    upload_ids = upload_ids.select { |upload_id| Upload.exists?(upload_id) }
    self.class.ensure_wizard_upload_references!(@data[:id], upload_ids)
  end
end
