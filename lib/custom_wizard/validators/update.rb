class ::CustomWizard::UpdateValidator
  attr_reader :updater
  
  def initialize(updater)
    @updater = updater
  end
  
  def perform
    updater.step.fields.each do |field|
      validate_field(field)
    end
  end
  
  def validate_field(field)
    return if field.type == 'text_only'
    
    field_id = field.id.to_s
    value = @updater.submission[field_id]
    min_length = false
    label = field.raw[:label] || I18n.t("#{field.key}.label")
    type = field.type
    required = field.required
    min_length = field.min_length if is_text_type(field)
    file_types = field.file_types
    format = field.format
    
    if required && !value
      @updater.errors.add(field_id, I18n.t('wizard.field.required', label: label))
    end

    if min_length && value.is_a?(String) && value.strip.length < min_length.to_i
      @updater.errors.add(field_id, I18n.t('wizard.field.too_short', label: label, min: min_length.to_i))
    end

    if is_url_type(field) && !check_if_url(value)
      @updater.errors.add(field_id, I18n.t('wizard.field.not_url', label: label))
    end

    if type === 'checkbox'
      @updater.submission[field_id] = standardise_boolean(value)
    end
    
    if type === 'upload' && value.present? && !validate_file_type(value, file_types)
      @updater.errors.add(field_id, I18n.t('wizard.field.invalid_file', label: label, types: file_types))
    end
    
    if ['date', 'date_time'].include?(type) && value.present? && !validate_date(value)
      @updater.errors.add(field_id, I18n.t('wizard.field.invalid_date'))
    end
    
    if type === 'time' && value.present? && !validate_time(value)
      @updater.errors.add(field_id, I18n.t('wizard.field.invalid_time'))
    end 
    
    self.class.field_validators.each do |validator|
      if type === validator[:type]
        validator[:block].call(field, value, @updater, @step_template)
      end
    end
  end
  
  def self.sorted_field_validators
    @sorted_field_validators ||= []
  end

  def self.field_validators
    sorted_field_validators.map { |h| { type: h[:type], block: h[:block] } }
  end

  def self.add_field_validator(priority = 0, type, &block)
    sorted_field_validators << { priority: priority, type: type, block: block }
    @sorted_field_validators.sort_by! { |h| -h[:priority] }
  end
  
  private
  
  def validate_file_type(value, file_types)
    file_types.split(',')
      .map { |t| t.gsub('.', '') }
      .include?(File.extname(value['original_filename'])[1..-1])
  end
  
  def validate_date(value)
    begin
      Date.parse(value)
      true
    rescue ArgumentError
      false
    end
  end
  
  def validate_time(value)
    begin
      Time.parse(value)
      true
    rescue ArgumentError
      false
    end
  end

  def is_text_type(field)
    ['text', 'textarea', 'composer'].include? field.type
  end

  def is_url_type(field)
    ['url'].include? field.type
  end

  def check_if_url(value)
    value =~ URI::regexp
  end
  
  def standardise_boolean(value)
    ActiveRecord::Type::Boolean.new.cast(value)
  end
end