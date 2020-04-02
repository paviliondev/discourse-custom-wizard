class CustomWizard::Action
  attr_accessor :data,
                :action,
                :user,
                :updater
  
  def initialize(params)
    @action = params[:action]
    @user = params[:user]
    @data = params[:data]
    @updater = params[:updater]
  end
  
  def perform
    ActiveRecord::Base.transaction { self.send(action['type'].to_sym) }
  end
  
  def mapper
    @mapper ||= CustomWizard::Mapper.new(user: user, data: data)
  end
  
  def create_topic
    params = basic_topic_params
    
    byebug
    
    if params[:title] && params[:raw]
      params[:category] = action_category
      params[:tags] = action_tags
      
      byebug

      creator = PostCreator.new(user, params)
      post = creator.create

      if creator.errors.present?
        updater.errors.add(:create_topic, creator.errors.full_messages.join(" "))
      elsif action['skip_redirect'].blank?
        data['redirect_on_complete'] = post.topic.url
      end
    end
  end
  
  def send_message
    return if action['required'].present? && data[action['required']].blank?
    
    params = basic_topic_params
    params[:target_usernames] = CustomWizard::Mapper.new(
      inputs: action['recipient'],
      data: data,
      user: user,
      opts: {
        multiple: true
      }
    ).output
    
    if params[:title] && params[:raw]
      params[:archetype] = Archetype.private_message
      
      creator = PostCreator.new(user, params)
      post = creator.create

      if creator.errors.present?
        updater.errors.add(:send_message, creator.errors.full_messages.join(" "))
      elsif action['skip_redirect'].blank?
        data['redirect_on_complete'] = post.topic.url
      end
    end
  end

  def update_profile
    return unless (profile_updates = action['profile_updates']).length

    attributes = { custom_fields: {} }

    profile_updates.each do |pu|
      pair = field['pairs'].first
      field = mapper.map_field(pair['key'], pair['key_type'])
      value = mapper.map_field(pair['value'], pair['value_type'])
      
      if field.include?("custom_field")
        attributes[:custom_fields][field] = value
      else
        attributes[field.to_sym] = value
      end
    end
    
    if attributes.present?
      user_updater = UserUpdater.new(user, user)
      user_updater.update(attributes)
    end
  end

  def send_to_api
    api_body = nil

    if action['api_body'] != ""
      begin
        api_body_parsed = JSON.parse(action['api_body'])
      rescue JSON::ParserError
        raise Discourse::InvalidParameters, "Invalid API body definition: #{action['api_body']} for #{action['title']}"
      end
      api_body = JSON.parse(mapper.interpolate(JSON.generate(api_body_parsed)))
    end

    result = CustomWizard::Api::Endpoint.request(user, action['api'], action['api_endpoint'], api_body)

    if error = result['error'] || (result[0] && result[0]['error'])
      error = error['message'] || error
      updater.errors.add(:send_to_api, error)
    else
      ## add validation callback
    end
  end
  
  def open_composer   
    if action['custom_title_enabled']
      title = mapper.interpolate(action['custom_title'])
    else
      title = data[action['title']]
    end
    
    url = "/new-topic?title=#{title}"

    if action['post_builder']
      post = mapper.interpolate(action['post_template'])
    else
      post = data[action['post']]
    end
    
    url += "&body=#{post}"
    
    if category_id = action_category
      if category = Category.find(category_id)
        url += "&category=#{category.full_slug('/')}"
      end
    end
    
    if tags = action_tags
      url += "&tags=#{tags.join(',')}"
    end
        
    data['redirect_on_complete'] = Discourse.base_uri + URI.encode(url)
  end

  def add_to_group
    groups = CustomWizard::Mapper.new(
      inputs: action['inputs'],
      data: data,
      user: user,
      opts: {
        multiple: true
      }
    ).output
        
    groups = groups.flatten.reduce([]) do |result, g|
      begin
        result.push(Integer(g))
      rescue ArgumentError
        group = Group.find_by(name: g)
        result.push(group.id) if group
      end
      
      result
    end
    
    if groups.present?
      groups.each do |group_id|
        group = Group.find(group_id) if group_id
        group.add(user) if group
      end
    end
  end

  def route_to
    url = mapper.interpolate(action['url'])
    
    if action['code']
      data[action['code']] = SecureRandom.hex(8)
      url += "&#{action['code']}=#{data[action['code']]}"
    end
    
    data['route_to'] = URI.encode(url)
  end
  
  private
  
  def action_category
    output = CustomWizard::Mapper.new(
      inputs: action['category'],
      data: data,
      user: user
    ).output
    
    if output.is_a?(Array)
      output.first
    elsif output.is_a?(Integer)
      output
    elsif output.is_a?(String)
      output.to_i
    end
  end
  
  def action_tags
    output = CustomWizard::Mapper.new(
      inputs: action['tags'],
      data: data,
      user: user,
    ).output
    
    if output.is_a?(Array)
      output.flatten
    elsif output.is_a?(Integer)
      [*output]
    elsif output.is_a?(String)
      [*output.to_i]
    end
  end
  
  def add_custom_fields(params = {})
    if (custom_fields = action['custom_fields']).present?
      custom_fields.each do |field|
        pair = field['pairs'].first
        value = mapper.map_field(pair['key'], pair['key_type'])
        key = mapper.map_field(pair['value'], pair['value_type'])
        
        if key && 
          value.present? &&
          (keyArr = key.split('.')).length === 2

          if keyArr.first === 'topic'
            params[:topic_opts] ||= {}
            params[:topic_opts][:custom_fields] ||= {}
            params[:topic_opts][:custom_fields][keyArr.last] = value
          elsif keyArr.first === 'post'
            params[:custom_fields] ||= {}
            params[:custom_fields][keyArr.last.to_sym] = value
          end
        end
      end
    end
    
    params
  end
  
  def basic_topic_params
    params = {
      skip_validations: true
    }
    
    params[:title] = CustomWizard::Mapper.new(
      inputs: action['title'],
      data: data,
      user: user
    ).output

    params[:raw] = action['post_builder'] ?
      mapper.interpolate(action['post_template']) :
      data[action['post']]
    
    params = add_custom_fields(params)
    
    params
  end
end