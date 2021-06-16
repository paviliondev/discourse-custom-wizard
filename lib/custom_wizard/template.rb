# frozen_string_literal: true

class CustomWizard::Template
  include HasErrors

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
    end

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

  def self.remove(wizard_id)
    wizard = CustomWizard::Wizard.create(wizard_id)
    return false if !wizard

    ActiveRecord::Base.transaction do
      PluginStore.remove(CustomWizard::PLUGIN_NAME, wizard.id)
      clear_user_wizard_redirect(wizard_id)
    end

    Jobs.cancel_scheduled_job(:set_after_time_wizard) if wizard.after_time

    true
  end

  def self.exists?(wizard_id)
    PluginStoreRow.exists?(plugin_name: 'custom_wizard', key: wizard_id)
  end

  def self.list(setting: nil, order: :id)
    query = "plugin_name = 'custom_wizard'"
    query += "AND (value::json ->> '#{setting}')::boolean IS TRUE" if setting

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

  def self.clear_user_wizard_redirect(wizard_id)
    UserCustomField.where(name: 'redirect_to_wizard', value: wizard_id).destroy_all
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
        Jobs.cancel_scheduled_job(:set_after_time_wizard, wizard_id: wizard_id)
        self.class.clear_user_wizard_redirect(wizard_id)
      end
    end
  end

  def remove_non_mapped_index(object)
    if !object[:index].is_a?(Array)
      object.delete(:index)
    end
  end
end
