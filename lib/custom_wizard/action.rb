class CustomWizard::Action
  attr_accessor :data,
                :action,
                :user,
                :updater,
                :result
  
  def initialize(params)
    @wizard = params[:wizard]
    @action = params[:action]
    @user = params[:user]
    @data = params[:data]
    @updater = params[:updater]
    @log = []
  end
  
  def perform
    ActiveRecord::Base.transaction do
      self.send(action['type'].to_sym)
    end
    
    log = "wizard: #{@wizard.id}; action: #{action['type']}; user: #{user.username}"
    
    if @log.any?
      @log.each do |item|
        log << "; result: "
        log << item.to_s
      end
    end
    
    CustomWizard::Log.create(log)
  end
  
  def mapper
    @mapper ||= CustomWizard::Mapper.new(user: user, data: data)
  end
  
  def create_topic
    params = basic_topic_params
            
    if params[:title].present? && params[:raw].present?
      params[:category] = action_category
      params[:tags] = action_tags
      
      creator = PostCreator.new(user, params)
      post = creator.create
            
      if creator.errors.present?
        messages = creator.errors.full_messages.join(" ")
        log_error("failed to create", messages)
        updater.errors.add(:create_topic, messages)
      elsif action['skip_redirect'].blank?
        data['redirect_on_complete'] = post.topic.url
      end
      
      if creator.errors.blank?
        log_success("created topic", post.topic.id)
      end
    else
      log_error("invalid topic params")
    end
  end
  
  def send_message
    return if action['required'].present? && data[action['required']].blank?
    
    params = basic_topic_params
    params[:target_usernames] = CustomWizard::Mapper.new(
      inputs: action['recipient'],
      data: data,
      user: user
    ).perform
        
    if params[:title].present? && params[:raw].present? && params[:target_usernames].present?
      params[:archetype] = Archetype.private_message
      
      creator = PostCreator.new(user, params)
      post = creator.create

      if creator.errors.present?
        messages = creator.errors.full_messages.join(" ")
        log_error("failed to create message", messages)
        updater.errors.add(:send_message, messages)
      elsif action['skip_redirect'].blank?
        data['redirect_on_complete'] = post.topic.url
      end
      
      if creator.errors.blank?
        log_error("created message", post.topic.id)
      end
    else
      log_error("invalid message params")
    end
  end

  def update_profile
    return unless (profile_updates = action['profile_updates']).length
    params = {}
    
    profile_updates.first[:pairs].each do |pair|
      if allowed_profile_fields.include?(pair['key'])
        key = cast_profile_key(pair['key']).to_sym
        value = mapper.map_field(pair['value'], pair['value_type'])     
        params[key] = cast_profile_value(value, pair['key'])
      end
    end
    
    params = add_custom_fields(params)
    
    if params.present?
      result = UserUpdater.new(Discourse.system_user, user).update(params)
      
      if params[:avatar].present?
        result = update_avatar(params[:avatar])
      end
      
      if result
        log_success("updated profile fields", params.keys.map{ |p| p.to_s }.join(','))
      else
        log_error("failed to update profile fields")
      end
    else
      log_error("invalid profile fields params")
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
      inputs: action['group'],
      data: data,
      user: user,
      opts: {
        multiple: true
      }
    ).perform
        
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
        result = group.add(user) if group
      end
    end
    
    if result
      log_success("added to groups", groups.map { |g| g.id.to_s }.join(','))
    else
      log_error("failed to add to groups")
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
    ).perform
    
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
    ).perform
        
    if output.is_a?(Array)
      output.flatten
    else output.is_a?(String)
      [*output]
    end
  end
  
  def add_custom_fields(params = {})
    if (custom_fields = action['custom_fields']).present?
      field_map = CustomWizard::Mapper.new(
        inputs: custom_fields,
        data: data,
        user: user
      ).perform
      
      field_map.each do |field|
        keyArr = field[:key].split('.')
        value = field[:value]
        
        if keyArr.first === 'topic'
          params[:topic_opts] ||= {}
          params[:topic_opts][:custom_fields] ||= {}
          params[:topic_opts][:custom_fields][keyArr.last] = value
        else
          params[:custom_fields] ||= {}
          params[:custom_fields][keyArr.last.to_sym] = value
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
    ).perform

    params[:raw] = action['post_builder'] ?
      mapper.interpolate(action['post_template']) :
      data[action['post']]
    
    add_custom_fields(params)
  end
  
  def profile_url_fields
    ['profile_background', 'card_background']
  end
  
  def cast_profile_key(key)
    if profile_url_fields.include?(key)
      "#{key}_upload_url"
    else
      key
    end
  end
  
  def cast_profile_value(value, key)
    if profile_url_fields.include?(key)
      value['url']
    elsif key === 'avatar'
      value['id']
    else
      value
    end
  end
  
  def profile_excluded_fields
    ['username', 'email', 'trust_level'].freeze
  end
  
  def allowed_profile_fields
    CustomWizard::Mapper.user_fields.select { |f| profile_excluded_fields.exclude?(f) } + 
    profile_url_fields + 
    ['avatar']
  end
  
  def update_avatar(upload_id)
    user.create_user_avatar unless user.user_avatar
    user.user_avatar.custom_upload_id = upload_id
    user.uploaded_avatar_id = upload_id
    user.save!
    user.user_avatar.save!
  end
  
  def log_success(message, detail = nil)
    @log.push("success - #{message} - #{detail}")
  end
  
  def log_error(message, detail = nil)
    @log.push("error - #{message} - #{detail}")
  end
end