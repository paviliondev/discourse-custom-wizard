class CustomWizard::Submission
  include ActiveModel::SerializerSupport

  KEY ||= "submissions"
  ACTION_KEY ||= "action"
  META ||= %w(submitted_at route_to redirect_on_complete redirect_to)

  attr_reader :id,
              :user,
              :wizard
  
  attr_accessor :fields

  META.each do |attr|
    class_eval { attr_accessor attr }
  end

  def initialize(wizard, data = {}, user_id = nil)
    @wizard = wizard

    if user_id
      @user = User.find_by(id: user_id) || OpenStruct.new(deleted: true, id: user_id)
    else
      @user = wizard.user 
    end

    data = data.with_indifferent_access
    @id = data['id'] || SecureRandom.hex(12)
    @fields = data.except(META + ['id']) || {}

    META.each do |attr|
      send("#{attr}=", data[attr]) if data[attr]
    end
  end

  def save
    return nil unless wizard.save_submissions
    validate_fields

    submissions = self.class.list(wizard, user_id: user.id).select { |s| s.id != self.id }
    submissions.push(self)

    submission_data = submissions.map { |s| s.fields_and_meta }
    PluginStore.set("#{wizard.id}_#{KEY}", user.id, submission_data)
  end

  def validate_fields
    self.fields = fields.select do |key, value|
      wizard.field_ids.include?(key) || key.include?(ACTION_KEY)
    end
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

  def self.get(wizard, user_id)
    data = PluginStore.get("#{wizard.id}_#{KEY}", user_id).first
    new(wizard, data, user_id)
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