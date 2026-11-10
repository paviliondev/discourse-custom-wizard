# frozen_string_literal: true
require "addressable/uri"

class ::CustomWizard::UpdateValidator
  attr_reader :updater

  def initialize(updater)
    @updater = updater
  end

  def perform
    updater.step.fields.each { |field| validate_field(field) }
  end

  def validate_field(field)
    return if field.type == "text_only"

    field_id = field.id.to_s
    value = @updater.submission[field_id]
    min_length = false
    label = field.raw[:label]
    type = field.type
    required = field.required
    min_length = field.min_length if is_text_type(field)
    max_length = field.max_length if is_text_type(field)
    file_types = field.file_types
    format = field.format

    if required && !value
      @updater.errors.add(field_id, I18n.t("wizard.field.required", label: label))
    end

    if value.is_a?(String) && (stripped_length = value.strip.length) > 0
      if min_length.present? && stripped_length < min_length.to_i
        @updater.errors.add(
          field_id,
          I18n.t("wizard.field.too_short", label: label, min: min_length.to_i),
        )
      end

      if max_length.present? && stripped_length > max_length.to_i
        @updater.errors.add(
          field_id,
          I18n.t("wizard.field.too_long", label: label, max: max_length.to_i),
        )
      end
    end

    if is_url_type(field) && value.present? && !check_if_url(value)
      @updater.errors.add(field_id, I18n.t("wizard.field.not_url", label: label))
    end

    @updater.submission[field_id] = standardise_boolean(value) if type === "checkbox"

    if type === "upload" && value.present? && !validate_file_type(value, file_types)
      @updater.errors.add(
        field_id,
        I18n.t("wizard.field.invalid_file", label: label, types: file_types),
      )
    end

    if %w[date date_time].include?(type) && value.present? && !validate_date(value, format)
      @updater.errors.add(field_id, I18n.t("wizard.field.invalid_date"))
    end

    if type === "time" && value.present? && !validate_time(value)
      @updater.errors.add(field_id, I18n.t("wizard.field.invalid_time"))
    end

    validate_answer(field, field_id, value, label)
    validate_selection(field, field_id, value, label)

    self.class.field_validators.each do |validator|
      validator[:block].call(field, value, @updater) if type === validator[:type]
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

  # The browser only shows the options a field offers the user, so check them here too.
  def validate_selection(field, field_id, value, label)
    return if value.blank? || offered?(field, Array.wrap(value).flatten)

    @updater.errors.add(field_id, I18n.t("wizard.field.invalid_option", label: label))
  end

  def offered?(field, values)
    case field.type
    when "category"
      limit = field.limit.to_i
      key = field.property == "slug" ? :slug : :id
      (limit <= 0 || values.size <= limit) &&
        offered_records?(field, values, Category.secured(guardian), key)
    when "group"
      values.size == 1 && offered_records?(field, values, Site.new(guardian).groups, :id)
    when "dropdown"
      values.size == 1 && all_in?(values, content_ids(field))
    when "tag"
      CustomWizard::TagSearch.new(
        guardian,
        tag_groups: field.tag_groups,
        content: field.content,
      ).allows?(values, create: field.can_create_tag, limit: field.limit)
    else
      true
    end
  end

  # Values must match records in scope exactly, and be in the field's content if it has any.
  def offered_records?(field, values, scope, key)
    ids = content_ids(field)
    scope = scope.where(id: ids) if ids.any?
    all_in?(values, scope.where(key => values.map(&:to_s)).pluck(key))
  end

  def all_in?(values, allowed)
    (values.map(&:to_s) - allowed.map(&:to_s)).empty?
  end

  def content_ids(field)
    Array
      .wrap(field.content)
      .flatten
      .map { |item| (item.is_a?(Hash) ? item.with_indifferent_access[:id] : item).to_s }
  end

  def guardian
    @guardian ||= Guardian.new(@updater.step.wizard.user)
  end

  def validate_answer(field, field_id, value, label)
    return if %w[text dropdown].exclude?(field.type)
    return unless field.validations.is_a?(Hash)

    config = field.validations.with_indifferent_access[:answer]
    return if config.blank?
    return unless standardise_boolean(config[:status])
    return if value.blank?

    expected = config[:expected].to_s.strip
    return if expected.empty?

    actual = value.to_s.strip
    matched =
      if config[:match] == "insensitive"
        actual.casecmp?(expected)
      else
        actual == expected
      end
    return if matched

    @updater.errors.add(
      field_id,
      config[:message].presence || I18n.t("wizard.field.answer_incorrect", label: label),
    )
  end

  def validate_file_type(value, file_types)
    extension = File.extname(value["original_filename"].to_s).delete_prefix(".").downcase
    return false if extension.blank?

    file_types.split(",").map { |t| t.strip.delete_prefix(".").downcase }.include?(extension)
  end

  def validate_date(value, format)
    v8.eval("moment('#{value}', '#{format}', true).isValid()")
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
    %w[text textarea composer].include? field.type
  end

  def is_url_type(field)
    ["url"].include? field.type
  end

  SCHEMES = %w[http https]

  def check_if_url(url)
    parsed = Addressable::URI.parse(url) or return false
    SCHEMES.include?(parsed.scheme)
  rescue Addressable::URI::InvalidURIError
    false
  end

  def standardise_boolean(value)
    ActiveRecord::Type::Boolean.new.cast(value)
  end

  def v8
    return @ctx if @ctx
    @ctx = PrettyText.v8
    @ctx.load("#{Rails.root}/frontend/discourse/node_modules/moment/moment.js")
    @ctx
  end
end
