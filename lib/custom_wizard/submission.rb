# frozen_string_literal: true
class CustomWizard::Submission
  include ActiveModel::SerializerSupport

  PAGE_LIMIT = 50
  KEY ||= "submissions"
  META ||= %w(submitted_at route_to redirect_on_complete redirect_to)

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
    submissions = submission_list.submissions.select { |submission| submission.id != self.id }
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
    data = PluginStore.get("#{wizard.id}_#{KEY}", user_id).last
    new(wizard, data, user_id)
  end

  def self.list(wizard, user_id: nil, page: nil)
    params = { plugin_name: "#{wizard.id}_#{KEY}" }
    params[:key] = user_id if user_id.present?

    query = PluginStoreRow.where(params)
    result = OpenStruct.new(submissions: [], total: nil)

    query.each do |record|
      if (submission_data = ::JSON.parse(record.value)).any?
        submission_data.each do |data|
          result.submissions.push(new(wizard, data, record.key))
        end
      end
    end

    result.total = result.submissions.size

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
