class CustomWizard::Action
  attr_accessor :data,
                :action,
                :user,
                :result
  
  def initialize(params)
    @wizard = params[:wizard]
    @action = params[:action]
    @user = params[:user]
    @data = params[:data]
    @log = []
    @result = CustomWizard::ActionResult.new
  end
  
  def perform    
    ActiveRecord::Base.transaction do
      self.send(action['type'].to_sym)
    end
        
    if creates_post? && @result.success?
      @result.handler.enqueue_jobs
    end
    
    save_log
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
      elsif action['skip_redirect'].blank?
        data['redirect_on_complete'] = post.topic.url
      end
      
      if creator.errors.blank?
        log_success("created topic", "id: #{post.topic.id}")
        result.handler = creator
      end
    else
      log_error("invalid topic params", "title: #{params[:title]}; post: #{params[:raw]}")
    end
  end
  
  def send_message
    if action['required'].present? && data[action['required']].blank?
      log_error(
        "required not present",
        "required: #{action['required']}; data: #{data[action['required']]}"
      )
      return
    end
    
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
      elsif action['skip_redirect'].blank?
        data['redirect_on_complete'] = post.topic.url
      end
      
      if creator.errors.blank?
        log_success("created message", "id: #{post.topic.id}")
        result.handler = creator
      end
    else
      log_error(
        "invalid message params",
        "title: #{params[:title]}; post: #{params[:raw]}; recipients: #{params[:target_usernames]}"
      )
    end
  end

  def update_profile
    return unless (profile_updates = action['profile_updates']).length
    params = {}
    
    profile_updates.first[:pairs].each do |pair|
      if allowed_profile_field?(pair['key'])
        key = cast_profile_key(pair['key'])
        value = cast_profile_value(mapper.map_field(pair['value'], pair['value_type']), pair['key']) 
        
        if user_field?(pair['key'])
          params[:custom_fields] ||= {}
          params[:custom_fields][key] = value
        else
          params[key.to_sym] = value
        end
      end
    end
    
    params = add_custom_fields(params)
    
    if params.present?
      result = UserUpdater.new(Discourse.system_user, user).update(params)
      
      if params[:avatar].present?
        result = update_avatar(params[:avatar])
      end
      
      if result
        log_success("updated profile fields", "fields: #{params.keys.map(&:to_s).join(',')}")
      else
        log_error("failed to update profile fields", "result: #{result.inspect}")
      end
    else
      log_error("invalid profile fields params", "params: #{params.inspect}")
    end
  end

  def watch_categories

    watched_categories = CustomWizard::Mapper.new(
      inputs: action['categories'],
      data: data,
      user: user
    ).perform

    notification_level = action['notification_level']

    if notification_level.blank?
      log_error("Notifcation Level was not set! Exiting wizard action")
      return
    end

    mute_remainder = CustomWizard::Mapper.new(
      inputs: action['mute_remainder'],
      data: data,
      user: user
    ).perform

    Category.all.each do |category|
      if watched_categories.present? && watched_categories.include?(category.id.to_s)
       CategoryUser.set_notification_level_for_category(user, CategoryUser.notification_levels[notification_level.to_sym], category.id)
      elsif mute_remainder
        CategoryUser.set_notification_level_for_category(user, CategoryUser.notification_levels[:muted], category.id)
      end
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
      log_error("api request failed", "message: #{error}")
    else
      log_success("api request succeeded", "result: #{result}")
    end
  end
  
  def open_composer
    params = basic_topic_params
            
    if params[:title].present? && params[:raw].present?
      url = "/new-topic?title=#{params[:title]}"
      url += "&body=#{params[:raw]}"
      
      if category_id = action_category
        if category_id && category = Category.find(category_id)
          url += "&category=#{category.full_slug('/')}"
        end
      end
      
      if tags = action_tags
        url += "&tags=#{tags.join(',')}"
      end
      
      route_to = Discourse.base_uri + URI.encode(url)
      data['redirect_on_complete'] = route_to
      
      log_info("route: #{route_to}")
    else
      log_error("invalid composer params", "title: #{params[:title]}; post: #{params[:raw]}")
    end    
  end

  def add_to_group
    group_map = CustomWizard::Mapper.new(
      inputs: action['group'],
      data: data,
      user: user,
      opts: {
        multiple: true
      }
    ).perform
        
    groups = group_map.flatten.reduce([]) do |groups, g|
      begin
        groups.push(Integer(g))
      rescue ArgumentError
        group = Group.find_by(name: g)
        groups.push(group.id) if group
      end
      
      groups
    end
    
    result = nil
    
    if groups.present?
      groups.each do |group_id|
        group = Group.find(group_id) if group_id
        result = group.add(user) if group
      end
    end
    
    if result
      log_success("added to groups", "groups: #{groups.map(&:to_s).join(',')}")
    else
      detail = groups.present? ? "groups: #{groups.map(&:to_s).join(',')}" : nil 
      log_error("failed to add to groups", detail)
    end
  end

  def route_to
    return unless (url_input = action['url']).present?
    
    if url_input.is_a?(String)
      url = mapper.interpolate(url_input)
    else
      url = CustomWizard::Mapper.new(
        inputs: url_input,
        data: data,
        user: user
      ).perform
    end
        
    if action['code']
      data[action['code']] = SecureRandom.hex(8)
      url += "&#{action['code']}=#{data[action['code']]}"
    end
    
    route_to = URI.encode(url)
    data['route_to'] = route_to
    
    log_info("route: #{route_to}")
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
  
  def creates_post?
    [:create_topic, :send_message].include?(action['type'].to_sym)
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
  
  def allowed_profile_field?(field)
    allowed_profile_fields.include?(field) || user_field?(field)
  end
  
  def user_field?(field)
    field.to_s.include?(::User::USER_FIELD_PREFIX) &&
    ::UserField.exists?(field.split('_').last.to_i) 
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
    @log.push("success: #{message} - #{detail}")
    @result.success = true
  end
  
  def log_error(message, detail = nil)
    @log.push("error: #{message} - #{detail}")
    @result.success = false
  end
  
  def log_info(message, detail = nil)
    @log.push("info: #{message} - #{detail}")
  end
  
  def save_log
    log = "wizard: #{@wizard.id}; action: #{action['type']}; user: #{user.username}"
    
    if @log.any?
      @log.each do |item|
        log << "; #{item.to_s}"
      end
    end
    
    CustomWizard::Log.create(log)
  end
end