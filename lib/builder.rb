class CustomWizard::Builder

  attr_accessor :wizard, :updater, :submissions

  def initialize(user, wizard_id)
    data = PluginStore.get('custom_wizard', wizard_id)

    return if data.blank?

    @steps = data['steps']
    @wizard = CustomWizard::Wizard.new(user,
      id: wizard_id,
      save_submissions: data['save_submissions'],
      multiple_submissions: data['multiple_submissions'],
      background: data["background"],
      name: data["name"],
      after_time: data["after_time"],
      after_signup: data["after_signup"],
      required: data["required"],
      min_trust: data["min_trust"]
    )
    @submissions = Array.wrap(PluginStore.get("#{wizard_id}_submissions", user.id))
  end

  def self.sorted_handlers
    @sorted_handlers ||= []
  end

  def self.step_handlers
    sorted_handlers.map { |h| { wizard_id: h[:wizard_id], block: h[:block] } }
  end

  def self.add_step_handler(priority = 0, wizard_id, &block)
    sorted_handlers << { priority: priority, wizard_id: wizard_id, block: block }
    @sorted_handlers.sort_by! { |h| -h[:priority] }
  end

  USER_FIELDS = ['name', 'username', 'email', 'date_of_birth', 'title', 'locale']
  PROFILE_FIELDS = ['location', 'website', 'bio_raw', 'profile_background', 'card_background']

  def self.build_post(template, user, data)
    post = template.gsub(/u\{(.*?)\}/) do |match|
      result = ''
      result = user.send($1) if USER_FIELDS.include?($1)
      result = user.user_profile.send($1) if PROFILE_FIELDS.include?($1)
      result
    end
    post.gsub!(/w\{(.*?)\}/) { |match| data[$1.to_sym] }
  end

  def build
    unless (@wizard.completed? && !@wizard.multiple_submissions && !@wizard.user.admin) || !@steps || !@wizard.permitted?
      @steps.each do |s|
        @wizard.append_step(s['id']) do |step|
          step.title = s['title'] if s['title']
          step.description = s['description'] if s['description']
          step.banner = s['banner'] if s['banner']
          step.key = s['key'] if s['key']

          if s['fields'] && s['fields'].length
            s['fields'].each do |f|
              params = {
                id: f['id'],
                type: f['type'],
                required: f['required']
              }

              params[:label] = f['label'] if f['label']
              params[:description] = f['description'] if f['description']
              params[:key] = f['key'] if f['key']

              if @submissions.last && @wizard.unfinished?
                submission = @submissions.last
                params[:value] = submission[f['id']] if submission[f['id']]
              end

              if s['actions'] && s['actions'].any?
                profile_actions = s['actions'].select { |a| a['type'] === 'update_profile' }
                if profile_actions.any?
                  profile_actions.each do |action|
                    if update = action['profile_updates'].select { |u| u['key'] === f['id'] }.first
                      attribute = update['value']
                      custom_field = update['value_custom']
                      if custom_field
                        params[:value] = UserCustomField.where(user_id: @wizard.user.id, name: custom_field).pluck(:value)
                      elsif UserProfile.column_names.include? attribute
                        params[:value] = UserProfile.find_by(user_id: @wizard.user.id).send(attribute)
                      elsif User.column_names.include? attribute
                        params[:value] = User.find(@wizard.user.id).send(attribute)
                      end
                    end
                  end
                end
              end

              field = step.add_field(params)

              if f['type'] === 'dropdown'
                field.dropdown_none = f['dropdown_none'] if f['dropdown_none']

                if f['choices'] && f['choices'].length > 0
                  f['choices'].each do |c|
                    field.add_choice(c['value'], label: c['label'])
                  end
                elsif f['choices_key'] && f['choices_key'].length > 0
                  choices = I18n.t(f['choices_key'])
                  if choices.is_a?(Hash)
                    choices.each do |k, v|
                      field.add_choice(k, label: v)
                    end
                  end
                elsif f['choices_preset'] && f['choices_preset'].length > 0
                  objects = []

                  if f['choices_preset'] === 'categories'
                    objects = Site.new(Guardian.new(@wizard.user)).categories
                  end

                  if f['choices_filters'] && f['choices_filters'].length > 0
                    f['choices_filters'].each do |f|
                      objects.reject! do |o|
                        prop = f['key']
                        if prop.include? 'custom_fields'
                          o.custom_fields[prop.split('.')[1]].to_s != f['value'].to_s
                        else
                          o[prop].to_s != f['value'].to_s
                        end
                      end
                    end
                  end

                  if objects.length > 0
                    objects.each do |o|
                      field.add_choice(o.id, label: o.name)
                    end
                  end
                end
              end
            end
          end

          step.on_update do |updater|
            @updater = updater
            user = @wizard.user

            if s['fields'] && s['fields'].length
              s['fields'].each do |f|
                value = updater.fields[f['id']]
                min_length = f['min_length']
                if min_length && value.is_a?(String) && value.length < min_length.to_i
                  label = f['label'] || I18n.t("#{f['key']}.label")
                  updater.errors.add(f['id'].to_s, I18n.t('wizard.field.too_short', label: label, min: min_length.to_i))
                end
              end
            end

            next if updater.errors.any?

            CustomWizard::Builder.step_handlers.each do |handler|
              if handler[:wizard_id] == @wizard.id
                handler[:block].call(self)
              end
            end

            next if updater.errors.any?

            step_input = updater.fields.to_h
            data = step_input
            final_step = updater.step.next.nil?

            ## if the wizard has data from the previous steps make that accessible to the actions.
            if @submissions && @submissions.last && !@submissions.last.key?("submitted_at")
              submission = @submissions.last
              data = submission.merge(data)
            end

            if s['actions'] && s['actions'].length
              s['actions'].each do |a|
                if a['type'] === 'create_topic' && data

                  if a['custom_title']
                    title = a['custom_title']
                  else
                    title = data[a['title']]
                  end

                  if a['post_builder']
                    post = CustomWizard::Builder.build_post(a['post_template'], user, data)
                  else
                    post = data[a['post']]
                  end

                  if title
                    params = {
                      title: title,
                      raw: post,
                      skip_validations: true
                    }

                    if a['custom_category_enabled'] &&
                      !a['custom_category_wizard_field'] &&
                      a['custom_category_user_field_key']
                      if a['custom_category_user_field_key'].include?('custom_fields')
                        field = a['custom_category_user_field_key'].split('.').last
                        category_id = user.custom_fields[field]
                      else
                        category_id = user.send(a['custom_category_user_field_key'])
                      end
                    else
                      category_id = a['category_id']
                    end

                    params[:category] = category_id

                    topic_custom_fields = {}

                    if a['add_fields']
                      a['add_fields'].each do |f|
                        if f['value_custom']
                          value = f['value_custom']
                        else
                          value = data[f['value']]
                        end
                        key = f['key']

                        if key && key.include?('custom_fields')
                          keyArr = key.split('.')

                          if keyArr.length === 3
                            custom_key = keyArr.last
                            type = keyArr.first

                            if type === 'topic'
                              topic_custom_fields[custom_key] = value
                            elsif type === 'post'
                              params[:custom_fields] ||= {}
                              params[:custom_fields][custom_key.to_sym] = value
                            end
                          end
                        else
                          params[key.to_sym] = value
                        end
                      end
                    end

                    creator = PostCreator.new(user, params)
                    post = creator.create

                    if creator.errors.present?
                      updater.errors.add(:create_topic, creator.errors.full_messages.join(" "))
                    else
                      if topic_custom_fields.present?
                        topic_custom_fields.each do |k, v|
                          post.topic.custom_fields[k] = v
                        end
                        post.topic.save_custom_fields(true)
                      end

                      data['redirect_to'] = post.topic.url
                    end
                  end
                end

                if a['type'] === 'send_message' && data
                  title = data[a['title']]

                  if a['post_builder']
                    post = CustomWizard::Builder.build_post(a['post_template'], user, data)
                  else
                    post = data[a['post']]
                  end

                  if title && post
                    creator = PostCreator.new(user,
                                    title: title,
                                    raw: post,
                                    archetype: Archetype.private_message,
                                    target_usernames: a['username'])

                    post = creator.create

                    if creator.errors.present?
                      updater.errors.add(:send_message, creator.errors.full_messages.join(" "))
                    else
                      data['redirect_to'] = post.topic.url
                    end
                  end
                end

                if a['type'] === 'update_profile' && a['profile_updates'].length && data
                  attributes = {}
                  custom_fields = {}

                  a['profile_updates'].each do |pu|
                    value = pu['value']
                    custom_field = pu['value_custom']
                    key = pu['key']

                    if custom_field
                      custom_fields[custom_field] = data[key]
                    else
                      attributes[value.to_sym] = data[key]
                    end
                  end

                  if custom_fields.present?
                    custom_fields.each do |k, v|
                      user.custom_fields[k] = v
                    end
                    user.save_custom_fields(true)
                  end

                  if attributes.present?
                    user_updater = UserUpdater.new(user, user)
                    user_updater.update(attributes)
                  end
                end
              end
            end

            if @wizard.save_submissions && updater.errors.empty?
              if step_input
                step_input.each do |key, value|
                  data[key] = value
                end
              end

              if final_step
                data['submitted_at'] = Time.now.iso8601
              end

              if data.present?
                @submissions.pop(1) if @wizard.unfinished?
                @submissions.push(data)
                PluginStore.set("#{@wizard.id}_submissions", @wizard.user.id, @submissions)
              end
            end

            # Ensure there is no submission left over after the user has completed a wizard with save_submissions off
            if !@wizard.save_submissions && final_step
              PluginStore.remove("#{@wizard.id}_submissions", @wizard.user.id)
            end

            if @wizard.after_time && final_step
              @wizard.user.custom_fields.delete('redirect_to_wizard');
              @wizard.user.save_custom_fields(true)
            end

            if updater.errors.empty?
              # If the user will be redirected to a new wizard send them there straight away
              user_redirect = user.custom_fields['redirect_to_wizard']
              redirect_to = user_redirect ? "/w/#{user_redirect}" : data['redirect_to']
              updater.result = { redirect_to: redirect_to } if redirect_to
            end
          end
        end
      end
    end

    @wizard
  end
end
