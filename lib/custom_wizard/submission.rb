# frozen_string_literal: true
class CustomWizard::Submission
  include ActiveModel::SerializerSupport

  PAGE_LIMIT = 50
  KEY ||= "submissions"
  META ||= %w(updated_at submitted_at route_to redirect_on_complete redirect_to)

  attr_reader :id,
              :wizard

  attr_accessor :fields,
                :permitted_param_keys

  META.each do |attr|
    class_eval { attr_accessor attr }
  end

  def initialize(wizard, data = {})
    @wizard = wizard

    data = (data || {}).with_indifferent_access
    @id = data['id'] || SecureRandom.hex(12)
    non_field_keys = META + ['id']
    @fields = data.except(*non_field_keys) || {}

    META.each do |attr|
      send("#{attr}=", data[attr]) if data[attr]
    end

    @permitted_param_keys = data['permitted_param_keys'] || []
  end

  def save
    return nil unless wizard.save_submissions
    validate

    submission_list = self.class.list(wizard)
    submissions = submission_list.submissions.select { |submission| submission.id != self.id }
    self.updated_at = Time.now.iso8601
    submissions.push(self)

    submission_data = submissions.map { |submission| data_to_save(submission)  }
    PluginStore.set("#{wizard.id}_#{KEY}", wizard.actor_id, submission_data)
  end

  def validate
    self.fields = fields.select { |key, value| validate_field_key(key) }
  end

  def validate_field_key(key)
    wizard.field_ids.include?(key) ||
    wizard.action_ids.include?(key) ||
    permitted_param_keys.include?(key)
  end

  def fields_and_meta
    result = fields

    META.each do |attr|
      if value = self.send(attr)
        result[attr] = value
      end
    end

    result
  end

  def present?
    fields_and_meta.present?
  end

  def data_to_save(submission)
    data = {
      id: submission.id
    }

    data.merge!(submission.fields_and_meta)

    if submission.permitted_param_keys.present?
      data[:permitted_param_keys] = submission.permitted_param_keys
    end

    data
  end

  def submitted?
    !!submitted_at
  end

  def self.get(wizard)
    data = PluginStore.get("#{wizard.id}_#{KEY}", wizard.actor_id).last
    new(wizard, data)
  end

  def remove
    if present?
      data = PluginStore.get("#{@wizard.id}_#{KEY}", wizard.actor_id)
      data.delete_if { |sub| sub["id"] == @id }
      PluginStore.set("#{@wizard.id}_#{KEY}", wizard.actor_id, data)
    end
  end

  def self.cleanup_incomplete_submissions(wizard)
    all_submissions = list(wizard)
    sorted_submissions = all_submissions.submissions.sort_by do |submission|
      zero_epoch_time = DateTime.strptime("0", '%s')
      [
        submission.submitted_at ? Time.iso8601(submission.submitted_at) : zero_epoch_time,
        submission.updated_at ? Time.iso8601(submission.updated_at) : zero_epoch_time
      ]
    end.reverse

    has_incomplete = false
    valid_submissions = sorted_submissions.select do |submission|
      to_be_included = submission.submitted_at || !has_incomplete
      has_incomplete = true if !submission.submitted_at

      to_be_included
    end

    valid_data = valid_submissions.map { |submission| submission.data_to_save(submission) }
    PluginStore.set("#{wizard.id}_#{KEY}", wizard.actor_id, valid_data)
  end

  def self.list(wizard, order_by: nil, page: nil)
    list_actor_id = wizard.actor_id
    list_user = wizard.user if wizard.user.present?

    params = { plugin_name: "#{wizard.id}_#{KEY}" }
    params[:key] = list_actor_id if list_actor_id

    query = PluginStoreRow.where(params)
    result = OpenStruct.new(submissions: [], total: nil)

    query.each do |record|
      if (submission_data = ::JSON.parse(record.value)).any?
        submission_user = list_user || User.find_by(id: record.key.to_i)

        submission_data.each do |data|
          _wizard = wizard.clone
          _wizard.user = submission_user if submission_user.present?
          result.submissions.push(new(_wizard, data))
        end
      end
    end

    result.total = result.submissions.size
    result.submissions.sort_by! { |h| [h.submitted_at ? 1 : 0, h.submitted_at] }.reverse!

    if !page.nil?
      start = page * PAGE_LIMIT
      length = PAGE_LIMIT

      if result.submissions.length > start
        result.submissions = result.submissions[start, length]
      else
        result.submissions = []
      end
    end

    result
  end
end
