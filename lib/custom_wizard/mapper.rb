class CustomWizard::Mapper
  attr_accessor :inputs, :data, :user
  
  USER_FIELDS = ['name', 'username', 'email', 'date_of_birth', 'title', 'locale', 'trust_level']
  PROFILE_FIELDS = ['location', 'website', 'bio_raw']
  OPERATORS = { 'eq': '==', 'gt': '>', 'lt': '<', 'gte': '>=', 'lte': '<=' }
 
  def initialize(params)
    @inputs = params[:inputs] || {}
    @data = params[:data] || {}
    @user = params[:user]
    @opts = params[:opts] || {}
  end
  
  def output
    multiple = @opts[:multiple]
    output = multiple ? [] : nil
    
    inputs.each do |input|
      if input['type'] === 'conditional' && validate_pairs(input['pairs'])
        if multiple
          output.push(map_field(input['output'], input['output_type']))
        else
          output = map_field(input['output'], input['output_type'])
          break
        end
      end
      
      if input['type'] === 'assignment'
        value = map_field(input['output'], input['output_type'])
        
        if @opts[:multiple]
          output.push(value)
        else
          output = value
          break
        end
      end
    end
          
    output
  end
  
  def validate_pairs(pairs)
    failed = false
    
    pairs.each do |pair|
      key = map_field(pair['key'], pair['key_type'])
      value = map_field(pair['value'], pair['value_type'])
      failed = true unless key.public_send(operator(pair['connector']), value)
    end
    
    !failed
  end
  
  def operator(connector)
    OPERATORS[connector] || '=='
  end
  
  def map_field(value, type)
    method = "#{type}_field"
  
    if self.respond_to?(method)
      self.send(method, value)
    else
      value
    end
  end
  
  def wizard_field(value)
    data && !data.key?("submitted_at") && data[value]
  end

  def user_field(value)
    if value.include?('user_field_')
      UserCustomField.where(user_id: user.id, name: value).pluck(:value).first
    elsif PROFILE_FIELDS.include?(value)
      UserProfile.find_by(user_id: user.id).send(value)
    elsif USER_FIELDS.include?(value)
      User.find(user.id).send(value)
    end
  end
  
  def interpolate(string)
    result = string.gsub(/u\{(.*?)\}/) do |match|
      result = ''
      result = user.send($1) if USER_FIELDS.include?($1)
      result = user.user_profile.send($1) if PROFILE_FIELDS.include?($1)
      result
    end

    result = result.gsub(/w\{(.*?)\}/) { |match| recurse(data, [*$1.split('.')]) }
    
    result.gsub(/v\{(.*?)\}/) do |match|
      attrs = $1.split(':')
      key = attrs.first
      format = attrs.length > 1 ? attrs.last : nil
      val = nil
      
      if key == 'time'
        time_format = format.present? ? format : "%B %-d, %Y"
        val = Time.now.strftime(time_format)
      end

      val
    end
  end
  
  def recurse(data, keys)
    k = keys.shift
    result = data[k]
    keys.empty? ? result : self.recurse(result, keys)
  end
end