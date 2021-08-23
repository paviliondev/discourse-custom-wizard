# frozen_string_literal: true
class CustomWizard::Submission
  include ActiveModel::SerializerSupport

  KEY ||= "submissions"
  META ||= %w(updated_at submitted_at route_to redirect_on_complete redirect_to)

  attr_reader :id,
              :user,
              :user_id,
              :wizard

  attr_accessor :fields,
                :permitted_param_keys

  META.each do |attr|
    class_eval { attr_accessor attr }
  end

  def initialize(wizard, data = {}, user_id = nil)
    @wizard = wizard
    @user_id = user_id

    if user_id
      @user = User.find_by(id: user_id)
    else
      @user = wizard.user
    end

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

    submission_list = self.class.list(wizard, user_id: user.id)
    submissions = submission_list.select { |submission| submission.id != self.id }
    self.updated_at = Time.now.iso8601
    submissions.push(self)

    submission_data = submissions.map { |submission| data_to_save(submission)  }
    PluginStore.set("#{wizard.id}_#{KEY}", user.id, submission_data)
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

  def self.get(wizard, user_id)
    data = PluginStore.get("#{wizard.id}_#{KEY}", user_id).first
    new(wizard, data, user_id)
  end

  def remove
    if present?
      user_id = @user.id
      wizard_id = @wizard.id
      submission_id = @id
      data = PluginStore.get("#{wizard_id}_#{KEY}", user_id)
      data.delete_if { |sub| sub["id"] == submission_id }
      PluginStore.set("#{wizard_id}_#{KEY}", user_id, data)
    end
  end

  def self.cleanup_incomplete_submissions(wizard)
    user_id = wizard.user.id
    all_submissions = list(wizard, user_id: user_id)
    sorted_submissions = all_submissions.sort_by do |submission|
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
    PluginStore.set("#{wizard.id}_#{KEY}", user_id, valid_data)
  end

  def self.list(wizard, user_id: nil, order_by: nil)
    params = { plugin_name: "#{wizard.id}_#{KEY}" }
    params[:key] = user_id if user_id.present?

    query = PluginStoreRow.where(params)
    query = query.order("#{order_by} DESC") if order_by.present?

    result = []

    query.each do |record|
      if (submission_data = ::JSON.parse(record.value)).any?
        submission_data.each do |data|
          result.push(new(wizard, data, record.key))
        end
      end
    end

    result
  end
end
