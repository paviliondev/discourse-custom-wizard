class CustomWizard::Action
  attr_accessor :data,
                :action,
                :user,
                :guardian,
                :result
  
  def initialize(params)
    @wizard = params[:wizard]
    @action = params[:action]
    @user = params[:user]
    @guardian = Guardian.new(@user)
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
    
    if @result.success? && @result.output.present?
      data[action['id']] = @result.output
    end
    
    save_log
  end
  
  def mapper
    @mapper ||= CustomWizard::Mapper.new(user: user, data: data)
  end
  
  def create_topic
    params = basic_topic_params.merge(public_topic_params)
            
    if params[:title].present? && params[:raw].present?
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
        result.output = post.topic.id
      end
    else
      log_error("invalid topic params", "title: #{params[:title]}; post: #{params[:raw]}")
    end
  end
  
  def send_message

    if action['required'].present?
      required = CustomWizard::Mapper.new(
        inputs: action['required'],
        data: data,
        user: user
      ).perform
            
      if required.blank?
        log_error("required input not present")
        return
      end
    end
    
    params = basic_topic_params
    
    targets = CustomWizard::Mapper.new(
      inputs: action['recipient'],
      data: data,
      user: user,
      multiple: true
    ).perform
    
    if targets.blank?
      log_error("no recipients", "send_message has no recipients")
      return
    end
    
    targets.each do |target|
      if Group.find_by(name: target)
        params[:target_group_names] = target
      elsif User.find_by_username(target)
        params[:target_usernames] = target
      else
        #
      end
    end
        
    if params[:title].present? &&
       params[:raw].present? &&
       (params[:target_usernames].present? ||
        params[:target_group_names].present?)
       
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
        result.output = post.topic.id
      end
    else
      log_error(
        "invalid message params",
        "title: #{params[:title]}; post: #{params[:raw]}; recipients: #{params[:target_usernames]}"
      )
    end
  end

  def update_profile
    params = {}
        
    if (profile_updates = action['profile_updates'])
      profile_updates.first[:pairs].each do |pair|
        if allowed_profile_field?(pair['key'])
          key = cast_profile_key(pair['key'])
          value = cast_profile_value(
            mapper.map_field(
              pair['value'],
              pair['value_type']
            ),
            pair['key']
          )
          
          if user_field?(pair['key'])
            params[:custom_fields] ||= {}
            params[:custom_fields][key] = value
          else
            params[key.to_sym] = value
          end
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
        
    watched_categories = [*watched_categories].map(&:to_i)

    notification_level = action['notification_level']

    if notification_level.blank?
      log_error("Notifcation Level was not set. Exiting wizard action")
      return
    end

    mute_remainder = CustomWizard::Mapper.new(
      inputs: action['mute_remainder'],
      data: data,
      user: user
    ).perform
    
    users = []
    
    if action['usernames']
      mapped_users = CustomWizard::Mapper.new(
        inputs: action['usernames'],
        data: data,
        user: user
      ).perform
      
      if mapped_users.present?
        mapped_users = mapped_users.split(',')
          .map { |username| User.find_by(username: username) }
        users.push(*mapped_users)
      end
    end
    
    if ActiveRecord::Type::Boolean.new.cast(action['wizard_user'])
      users.push(user)
    end

    category_ids = Category.all.pluck(:id)
    set_level = CategoryUser.notification_levels[notification_level.to_sym]
    mute_level = CategoryUser.notification_levels[:muted]
            
    users.each do |user|
      category_ids.each do |category_id|
        new_level = nil
        
        if watched_categories.include?(category_id) && set_level != nil
          new_level = set_level
        elsif mute_remainder
          new_level = mute_level
        end
        
        if new_level
          CategoryUser.set_notification_level_for_category(user, new_level, category_id)
        end
      end
      
      if watched_categories.any?
        log_success("#{user.username} notifications for #{watched_categories} set to #{set_level}")
      end
      
      if mute_remainder
        log_success("#{user.username} notifications for all other categories muted")
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
        if category = Category.find_by(id: category_id)
          url += "&category=#{category.full_slug('/')}"
        end
      end
      
      if tags = action_tags
        url += "&tags=#{tags.join(',')}"
      end
      
      route_to = Discourse.base_uri + URI.encode(url)
      data['route_to'] = route_to
      
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
    
    group_map = group_map.flatten.compact
    
    unless group_map.present?
      log_error("invalid group map")
      return
    end
        
    groups = group_map.reduce([]) do |groups, g|
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
  
  def create_group
    group =
      begin
        Group.new(new_group_params.except(:usernames, :owner_usernames))
      rescue ArgumentError => e
        raise Discourse::InvalidParameters, "Invalid group params"
      end
    
    if group.save
      def get_user_ids(username_string)
        User.where(username: username_string.split(",")).pluck(:id)
      end
      
      if new_group_params[:owner_usernames].present?
        owner_ids = get_user_ids(new_group_params[:owner_usernames])
        owner_ids.each { |user_id| group.group_users.build(user_id: user_id, owner: true) }
      end

      if new_group_params[:usernames].present?
        user_ids = get_user_ids(new_group_params[:usernames])
        user_ids -= owner_ids if owner_ids
        user_ids.each { |user_id| group.group_users.build(user_id: user_id) }
      end
      
      GroupActionLogger.new(user, group, skip_guardian: true).log_change_group_settings
      log_success("Group created", group.name)
      
      result.output = group.name
    else
      log_error("Group creation failed", group.errors.messages)
    end
  end
  
  def create_category    
    category =
      begin
        Category.new(new_category_params.merge(user: user))
      rescue ArgumentError => e
        raise Discourse::InvalidParameters, "Invalid category params"
      end
      
    if category.save
      StaffActionLogger.new(user).log_category_creation(category)
      log_success("Category created", category.name)
      result.output = category.id
    else
      log_error("Category creation failed", category.errors.messages)
    end
  end
  
  private
  
  def action_category
    output = CustomWizard::Mapper.new(
      inputs: action['category'],
      data: data,
      user: user
    ).perform
    
    return false unless output.present?
        
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
    
    return false unless output.present?
        
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
      
      registered_fields = CustomWizard::CustomField.list
      
      field_map.each do |field|
        keyArr = field[:key].split('.')
        value = field[:value]
        
        if keyArr.length > 1
          klass = keyArr.first
          name = keyArr.last
        else
          name = keyArr.first
        end
         
        
        registered = registered_fields.select { |f| f.name == name }
        if registered.first.present?
          klass = registered.first.klass
        end
                
        if klass === 'topic'
          params[:topic_opts] ||= {}
          params[:topic_opts][:custom_fields] ||= {}
          params[:topic_opts][:custom_fields][name] = value
        else
          params[:custom_fields] ||= {}
          params[:custom_fields][name] = value
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
    
    params[:import_mode] = ActiveRecord::Type::Boolean.new.cast(action['suppress_notifications'])
    
    add_custom_fields(params)
  end
  
  def public_topic_params
    params = {}
    
    if category = action_category
      params[:category] = category
    end
    
    if tags = action_tags
      params[:tags] = tags
    end
    
    if public_topic_fields.any?
      public_topic_fields.each do |field|
        unless action[field].nil? || action[field] == ""
          params[field.to_sym] = CustomWizard::Mapper.new(
            inputs: action[field],
            data: data,
            user: user
          ).perform
        end
      end
    end
    
    params
  end
  
  def new_group_params
    params = {}
    
    %w(
      name
      full_name
      title
      bio_raw
      owner_usernames
      usernames
      mentionable_level
      messageable_level
      visibility_level
      members_visibility_level
      grant_trust_level
    ).each do |attr|
      input = action[attr]
      
      if attr === "name" && input.blank?
        raise ArgumentError.new
      end
      
      if attr === "full_name" && input.blank?
        input = action["name"]
      end
      
      if input.present?        
        value = CustomWizard::Mapper.new(
          inputs: input,
          data: data,
          user: user
        ).perform
        
        if value
          value = value.parameterize(separator: '_') if attr === "name"
          value = value.to_i if attr.include?("_level")
          
          params[attr.to_sym] = value
        end
      end
    end
    
    add_custom_fields(params)
  end
  
  def new_category_params
    params = {}
    
    %w(
      name
      slug
      color
      text_color
      parent_category_id
      permissions
    ).each do |attr|
      if action[attr].present?        
        value = CustomWizard::Mapper.new(
          inputs: action[attr],
          data: data,
          user: user
        ).perform
        
        if value
          if attr === "parent_category_id" && value.is_a?(Array)
            value = value[0]
          end
          
          if attr === "permissions" && value.is_a?(Array)
            permissions = value
            value = {}
            
            permissions.each do |p|
              k = p[:key]
              v = p[:value].to_i
              
              if k.is_a?(Array)
                group = Group.find_by(id: k[0])
                k = group.name
              else
                k = k.parameterize(separator: '_')
              end
              
              value[k] = v 
            end
          end
          
          if attr === 'slug'
            value = value.parameterize(separator: '-')
          end
          
          params[attr.to_sym] = value
        end
      end
    end
    
    add_custom_fields(params)
  end
  
  def creates_post?
    [:create_topic, :send_message].include?(action['type'].to_sym)
  end
  
  def public_topic_fields
    ['visible']
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
    return value if value.nil?
    
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