class CustomWizard::Mapper
  attr_accessor :inputs, :data, :user
  
  USER_FIELDS = ['name', 'username', 'email', 'date_of_birth', 'title', 'locale', 'trust_level']
  PROFILE_FIELDS = ['location', 'website', 'bio_raw']
  
  def self.user_fields
    USER_FIELDS + PROFILE_FIELDS
  end
  
  OPERATORS = {
    equal: '==',
    greater: '>',
    less: '<',
    greater_or_equal: '>=',
    less_or_equal: '<=',
    regex: '=~',
    is: {
      present: "present?",
      true: "==",
      false: "=="
    }
  }
 
  def initialize(params)
    @inputs = params[:inputs] || {}
    @data = params[:data] || {}
    @user = params[:user]
    @opts = params[:opts] || {}
  end
  
  def perform
    multiple = @opts[:multiple]
    perform_result = multiple ? [] : nil
    
    inputs.each do |input|
      input_type = input['type']
      pairs = input['pairs']

      if (input_type === 'conditional' && validate_pairs(pairs)) || input_type === 'assignment'
        output = input['output']
        output_type = input['output_type']
        
        result = build_result(map_field(output, output_type), input_type)
                
        if multiple
          perform_result.push(result)
        else
          perform_result = result
          break
        end
      end
      
      if input_type === 'validation'
        result = build_result(validate_pairs(pairs), input_type)
        
        if multiple
          perform_result.push(result)
        else
          perform_result = result
          break
        end
      end
      
      if input_type === 'association'
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
      {
        type: type,
        result: result
      }
    else
      result
    end
  end
  
  def validate_pairs(pairs)
    pairs.all? do |pair|
      connector = pair['connector']
      operator = map_operator(connector)
      key = map_field(pair['key'], pair['key_type'])
      value = cast_value(map_field(pair['value'], pair['value_type']), key, connector)
      begin
        validation_result(key, value, operator)
      rescue NoMethodError
        #
      end
    end
  end
  
  def cast_value(value, key, connector)
    if connector == 'regex'
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
      elsif ["true", "false"].include?(value)
        result = key.public_send(operator, ActiveRecord::Type::Boolean.new.cast(value))
      end
    else
      result = key.public_send(operator, value)
    end
    
    if operator == '=~'
      result == 0 ? true : false
    else
      result
    end
  end
  
  def map_pairs(pairs)
    result = []
    
    pairs.each do |pair|
      key = map_field(pair['key'], pair['key_type'])
      value = map_field(pair['value'], pair['value_type'])
      
      if key && value
        result.push(
          key: key,
          value: value
        )
      end
    end
    
    result
  end
  
  def map_operator(connector)
    OPERATORS[connector.to_sym] || '=='
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

  def map_user_field(value)
    if value.include?(User::USER_FIELD_PREFIX)
      UserCustomField.where(user_id: user.id, name: value).pluck(:value).first
    elsif PROFILE_FIELDS.include?(value)
      UserProfile.find_by(user_id: user.id).send(value)
    elsif USER_FIELDS.include?(value)
      User.find(user.id).send(value)
    end
  end
  
  def map_user_field_options(value)
    if value.include?(User::USER_FIELD_PREFIX)
      if field = UserField.find_by(id: value.split('_').last)
        field.user_field_options.map(&:value)
      end
    end
  end
  
  def interpolate(string, opts={ user: true, wizard: true, value: true })    
    return string if string.blank?
        
    if opts[:user]
      string.gsub!(/u\{(.*?)\}/) do |match|
        result = ''
        result = user.send($1) if USER_FIELDS.include?($1)
        result = user.user_profile.send($1) if PROFILE_FIELDS.include?($1)
        result
      end
    end
    
    if opts[:wizard]
      string.gsub!(/w\{(.*?)\}/) do |match|
        value = recurse(data, [*$1.split('.')])
        value.present? ? value : ''
      end
    end
    
    if opts[:value]
      string.gsub!(/v\{(.*?)\}/) do |match|
        attrs = $1.split(':')
        key = attrs.first
        format = attrs.last if attrs.length > 1
        result = ''
        
        if key == 'time'
          time_format = format.present? ? format : "%B %-d, %Y"
          result = Time.now.strftime(time_format)
        end

        result
      end
    end
    
    string
  end
  
  def recurse(data, keys)
    k = keys.shift
    result = data[k]
    keys.empty? ? result : self.recurse(result, keys)
  end
end