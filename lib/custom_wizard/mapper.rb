# frozen_string_literal: true
class CustomWizard::Mapper
  attr_accessor :inputs, :data, :user

  USER_FIELDS = %w[name username date_of_birth title locale trust_level email]

  USER_OPTION_FIELDS = %w[email_level email_messages_level email_digests]

  PROFILE_FIELDS = %w[location website bio_raw]

  def self.user_fields
    USER_FIELDS + USER_OPTION_FIELDS + PROFILE_FIELDS
  end

  OPERATORS = {
    equal: "==",
    not_equal: "!=",
    greater: ">",
    less: "<",
    greater_or_equal: ">=",
    less_or_equal: "<=",
    regex: "=~",
    is: {
      present: "present?",
      true: "==",
      false: "==",
    },
  }

  def initialize(params)
    @inputs = params[:inputs] || {}
    @data = params[:data] ? params[:data].with_indifferent_access : {}
    @user = params[:user]
    @opts = params[:opts] || {}
  end

  def perform
    multiple = @opts[:multiple]
    perform_result = multiple ? [] : nil

    inputs.each do |input|
      input_type = input["type"]
      pairs = input["pairs"]

      if (input_type === "conditional" && validate_pairs(pairs)) || input_type === "assignment"
        output = input["output"]
        output_type = input["output_type"]

        result = build_result(map_field(output, output_type), input_type)

        if multiple
          perform_result.push(result)
        else
          perform_result = result
          break
        end
      end

      if input_type === "validation"
        result = build_result(validate_pairs(pairs), input_type)

        if multiple
          perform_result.push(result)
        else
          perform_result = result
          break
        end
      end

      if input_type === "association"
        result = build_result(map_pairs(pairs), input_type)

        if multiple
          perform_result.push(result)
        else
          perform_result = result
          break
        end
      end
    end

    perform_result
  end

  def build_result(result, type)
    if @opts[:with_type]
      { type: type, result: result }
    else
      result
    end
  end

  def validate_pairs(pairs)
    pairs.all? do |pair|
      connector = pair["connector"]
      operator = map_operator(connector)
      key = map_field(pair["key"], pair["key_type"])
      value = cast_value(map_field(pair["value"], pair["value_type"]), key, connector)
      begin
        validation_result(key, value, operator)
      rescue NoMethodError
        #
      end
    end
  end

  def cast_value(value, key, connector)
    if connector == "regex"
      Regexp.new(value)
    else
      if key.is_a?(String)
        value.to_s
      elsif key.is_a?(Integer)
        value.to_i
      else
        value
      end
    end
  end

  def validation_result(key, value, operator)
    result = nil

    if operator.is_a?(Hash) && (operator = operator[value.to_sym]).present?
      if value == "present"
        result = key.public_send(operator)
      elsif %w[true false].include?(value)
        result = bool(key).public_send(operator, bool(value))
      end
    elsif [key, value, operator].all? { |i| !i.nil? }
      result = key.public_send(operator, value)
    else
      result = false
    end

    if operator == "=~"
      result.nil? ? false : true
    else
      result
    end
  end

  def map_pairs(pairs)
    result = []

    pairs.each do |pair|
      key = map_field(pair["key"], pair["key_type"])
      value = map_field(pair["value"], pair["value_type"])

      result.push(key: key, value: value) if key && value
    end

    result
  end

  def map_operator(connector)
    OPERATORS[connector.to_sym] || "=="
  end

  def map_field(value, type)
    method = "map_#{type}"

    if self.respond_to?(method)
      self.send(method, value)
    else
      value
    end
  end

  def map_text(value)
    interpolate(value)
  end

  def map_wizard_field(value)
    data && !data.key?("submitted_at") && data[value]
  end

  def map_wizard_action(value)
    data && !data.key?("submitted_at") && data[value]
  end

  def map_user_field(value)
    return nil unless user

    if value.include?(User::USER_FIELD_PREFIX)
      user.custom_fields[value]
    elsif PROFILE_FIELDS.include?(value)
      user.user_profile.send(value)
    elsif USER_FIELDS.include?(value)
      user.send(value)
    elsif USER_OPTION_FIELDS.include?(value)
      user.user_option.send(value)
    elsif value.include?("avatar")
      get_avatar_url(value)
    else
      nil
    end
  end

  def map_user_field_options(value)
    if value.include?(User::USER_FIELD_PREFIX)
      if field = UserField.find_by(id: value.split("_").last)
        field.user_field_options.map(&:value)
      end
    end
  end

  def interpolate(string, opts = { user: true, wizard: true, value: true, template: false })
    return string if string.blank? || string.frozen?

    string.gsub!(/u\{(.*?)\}/) { |match| map_user_field($1) || "" } if opts[:user] && @user.present?

    string.gsub!(/w\{(.*?)\}/) { |match| recurse(data, [*$1.split(".")]) || "" } if opts[:wizard]

    if opts[:value]
      string.gsub!(/v\{(.*?)\}/) do |match|
        attrs = $1.split(":")
        key = attrs.first
        format = attrs.last if attrs.length > 1
        result = ""

        if key == "time"
          time_format = format.present? ? format : "%B %-d, %Y"
          result = Time.now.strftime(time_format)
        end

        result
      end
    end

    if opts[:template] #&& CustomWizard::Subscription.subscribed?
      template = Liquid::Template.parse(string)
      string = template.render(data)
    end

    string
  end

  def recurse(data, keys)
    return nil if data.nil?
    k = keys.shift
    result = data[k]

    if keys.empty?
      result.is_a?(Hash) ? "" : result
    else
      self.recurse(result, keys)
    end
  end

  def bool(value)
    ActiveRecord::Type::Boolean.new.cast(value)
  end

  def get_avatar_url(value)
    parts = value.split(".")
    valid_sizes = Discourse.avatar_sizes.to_a

    if value === "avatar" || parts.size === 1 || valid_sizes.exclude?(parts.last.to_i)
      user.small_avatar_url
    else
      user.avatar_template_url.gsub("{size}", parts.last)
    end
  end

  def self.mapped_value?(value)
    value.is_a?(Array) && value.all? { |v| v.is_a?(Hash) && v.key?("type") }
  end
end
