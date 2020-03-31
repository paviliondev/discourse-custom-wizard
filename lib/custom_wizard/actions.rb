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
    if action['custom_title_enabled']
      title = mapper.interpolate(action['custom_title'])
    else
      title = data[action['title']]
    end
    
    if action['post_builder']
      post = mapper.interpolate(action['post_template'])
    else
      post = data[action['post']]
    end
    
    if title
      params = {
        title: title,
        raw: post,
        skip_validations: true
      }

      params[:category] = action_category_id(action, data)
      tags = action_tags(action, data)
      params[:tags] = tags
      
      if action['add_fields']
        action['add_fields'].each do |field|
          value = field['value_custom'].present? ? field['value_custom'] : data[field['value']]
          key = field['key']
          
          if key && (value.present? || value === false)
            if key.include?('custom_fields')
              keyArr = key.split('.')

              if keyArr.length === 3
                custom_key = keyArr.last
                type = keyArr.first

                if type === 'topic'
                  params[:topic_opts] ||= {}
                  params[:topic_opts][:custom_fields] ||= {}
                  params[:topic_opts][:custom_fields][custom_key] = value
                elsif type === 'post'
                  params[:custom_fields] ||= {}
                  params[:custom_fields][custom_key.to_sym] = value
                end
              end
            else
              value = [*value] + [*tags] if key === 'tags'
              params[key.to_sym] = value
            end
          end
        end
      end

      creator = PostCreator.new(user, params)
      post = creator.create

      if creator.errors.present?
        updater.errors.add(:create_topic, creator.errors.full_messages.join(" "))
      else

        unless action['skip_redirect']
          data['redirect_on_complete'] = post.topic.url
        end
      end
    end
  end
  
  def send_message
    if action['required'].present? && data[action['required']].blank?
      return
    end
    
    if action['custom_title_enabled']
      title = mapper.interpolate(action['custom_title'])
    else
      title = data[action['title']]
    end

    if action['post_builder']
      post = mapper.interpolate(action['post_template'])
    else
      post = data[action['post']]
    end

    if title && post
      creator = PostCreator.new(user,
        title: title,
        raw: post,
        archetype: Archetype.private_message,
        target_usernames: action['username']
      )

      post = creator.create

      if creator.errors.present?
        updater.errors.add(:send_message, creator.errors.full_messages.join(" "))
      else
        unless action['skip_redirect']
          data['redirect_on_complete'] = post.topic.url
        end
      end
    end
  end

  def update_profile
    return unless action['profile_updates'].length

    attributes = {}
    custom_fields = {}

    action['profile_updates'].each do |pu|
      value = pu['value']
      key = pu['key']
      
      return if data[key].blank?

      if user_field || custom_field
        custom_fields[user_field || custom_field] = data[key]
      else
        updater_key = value
        if ['profile_background', 'card_background'].include?(value)
          updater_key = "#{value}_upload_url"
        end
        attributes[updater_key.to_sym] = data[key] if updater_key
      end

      if ['user_avatar'].include?(value)
        this_upload_id = data[key][:id]
        user.create_user_avatar unless user.user_avatar
        user.user_avatar.custom_upload_id = this_upload_id
        user.uploaded_avatar_id = this_upload_id
        user.save!
        user.user_avatar.save!
      end
    end

    if custom_fields.present?
      attributes[:custom_fields] = custom_fields
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
    
    if category_id = action_category_id
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
  
  def action_category_id
    if action['custom_category_enabled']
      if action['custom_category_wizard_field']
        data[action['category_id']]
      elsif action['custom_category_user_field_key']
        if action['custom_category_user_field_key'].include?('custom_fields')
          field = action['custom_category_user_field_key'].split('.').last
          user.custom_fields[field]
        else
          user.send(action['custom_category_user_field_key'])
        end
      end
    else
      action['category_id']
    end
  end
  
  def action_tags
    if action['custom_tag_enabled']
      data[action['custom_tag_field']]
    else
      action['tags']
    end
  end
end