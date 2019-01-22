class CustomWizard::Builder

  attr_accessor :wizard, :updater, :submissions

  def initialize(user, wizard_id)
    data = PluginStore.get('custom_wizard', wizard_id)

    return if data.blank?

    @steps = data['steps']
    @wizard = CustomWizard::Wizard.new(user, data)
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

  USER_FIELDS = ['name', 'username', 'email', 'date_of_birth', 'title', 'locale']
  PROFILE_FIELDS = ['location', 'website', 'bio_raw', 'profile_background', 'card_background']

  def self.fill_placeholders(string, user, data)
    result = string.gsub(/u\{(.*?)\}/) do |match|
      result = ''
      result = user.send($1) if USER_FIELDS.include?($1)
      result = user.user_profile.send($1) if PROFILE_FIELDS.include?($1)
      result
    end

    result.gsub(/w\{(.*?)\}/) { |match| data[$1.to_sym] }
  end

  def build(build_opts = {})
    unless (@wizard.completed? && !@wizard.multiple_submissions && !@wizard.user.admin) || !@steps || !@wizard.permitted?

      reset_submissions if build_opts[:reset]

      @steps.each do |step_template|
        @wizard.append_step(step_template['id']) do |step|
          step.title = step_template['title'] if step_template['title']
          step.description = step_template['description'] if step_template['description']
          step.banner = step_template['banner'] if step_template['banner']
          step.key = step_template['key'] if step_template['key']

          if step_template['fields'] && step_template['fields'].length
            step_template['fields'].each do |field_template|
              append_field(step, step_template, field_template, build_opts)
            end
          end

          step.on_update do |updater|
            @updater = updater
            user = @wizard.user

            if step_template['fields'] && step_template['fields'].length
              step_template['fields'].each do |field|
                validate_field(field, updater, step_template) if field['type'] != 'text-only'
              end
            end

            next if updater.errors.any?

            CustomWizard::Builder.step_handlers.each do |handler|
              if handler[:wizard_id] == @wizard.id
                handler[:block].call(self)
              end
            end

            next if updater.errors.any?

            data = updater.fields.to_h

            ## if the wizard has data from the previous steps make that accessible to the actions.
            if @submissions && @submissions.last && !@submissions.last.key?("submitted_at")
              submission = @submissions.last
              data = submission.merge(data)
            end

            if step_template['actions'] && step_template['actions'].length && data
              step_template['actions'].each do |action|
                self.send(action['type'].to_sym, user, action, data)
              end
            end

            final_step = updater.step.next.nil?

            if @wizard.save_submissions && updater.errors.empty?
              save_submissions(data, final_step)
            elsif final_step
              PluginStore.remove("#{@wizard.id}_submissions", @wizard.user.id)
            end

            if final_step && @wizard.id === @wizard.user.custom_fields['redirect_to_wizard']
              @wizard.user.custom_fields.delete('redirect_to_wizard');
              @wizard.user.save_custom_fields(true)
            end

            if updater.errors.empty?
              redirect_to = data['redirect_to']
              updater.result = { redirect_to: redirect_to } if redirect_to
            end
          end
        end
      end
    end

    @wizard
  end

  def append_field(step, step_template, field_template, build_opts)
    params = {
      id: field_template['id'],
      type: field_template['type'],
      required: field_template['required']
    }

    params[:label] = field_template['label'] if field_template['label']
    params[:description] = field_template['description'] if field_template['description']
    params[:image] = field_template['image'] if field_template['image']
    params[:key] = field_template['key'] if field_template['key']

    ## Load previously submitted values
    if !build_opts[:reset] && @submissions.last && !@submissions.last.key?("submitted_at")
      submission = @submissions.last
      params[:value] = submission[field_template['id']] if submission[field_template['id']]
    end

    ## If a field updates a profile field, load the current value
    if step_template['actions'] && step_template['actions'].any?
      profile_actions = step_template['actions'].select { |a| a['type'] === 'update_profile' }

      if profile_actions.any?
        profile_actions.each do |action|
          if update = action['profile_updates'].select { |u| u['key'] === field_template['id'] }.first
            params[:value] = prefill_profile_field(update)
          end
        end
      end
    end

    if field_template['type'] === 'checkbox'
      params[:value] = standardise_boolean(params[:value])
    end

    field = step.add_field(params)

    if field_template['type'] === 'dropdown'
      build_dropdown_list(field, field_template)
    end
  end

  def prefill_profile_field(update)
    attribute = update['value']
    custom_field = update['value_custom']
    user_field = update['user_field']

    if user_field || custom_field
      UserCustomField.where(user_id: @wizard.user.id, name: user_field || custom_field).pluck(:value)
    elsif UserProfile.column_names.include? attribute
      UserProfile.find_by(user_id: @wizard.user.id).send(attribute)
    elsif User.column_names.include? attribute
      User.find(@wizard.user.id).send(attribute)
    end
  end

  def build_dropdown_list(field, field_template)
    field.dropdown_none = field_template['dropdown_none'] if field_template['dropdown_none']

    if field_template['choices'] && field_template['choices'].length > 0
      field_template['choices'].each do |c|
        field.add_choice(c['key'], label: c['value'])
      end
    elsif field_template['choices_key'] && field_template['choices_key'].length > 0
      choices = I18n.t(field_template['choices_key'])

      if choices.is_a?(Hash)
        choices.each { |k, v| field.add_choice(k, label: v) }
      end
    elsif field_template['choices_preset'] && field_template['choices_preset'].length > 0
      objects = []

      if field_template['choices_preset'] === 'categories'
        objects = Site.new(Guardian.new(@wizard.user)).categories
      end

      if field_template['choices_filters'] && field_template['choices_filters'].length > 0
        field_template['choices_filters'].each do |f|
          objects.reject! do |o|
            if f['key'].include? 'custom_fields'
              o.custom_fields[f['key'].split('.')[1]].to_s != f['value'].to_s
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

  def validate_field(field, updater, step_template)
    value = updater.fields[field['id']]
    min_length = field['min_length']

    if min_length && value.is_a?(String) && value.strip.length < min_length.to_i
      label = field['label'] || I18n.t("#{field['key']}.label")
      updater.errors.add(field['id'].to_s, I18n.t('wizard.field.too_short', label: label, min: min_length.to_i))
    end

    ## ensure all checkboxes are booleans
    if field['type'] === 'checkbox'
      updater.fields[field['id']] = standardise_boolean(value)
    end

    CustomWizard::Builder.field_validators.each do |validator|
      if field['type'] === validator[:type]
        validator[:block].call(field, updater, step_template)
      end
    end
  end

  def standardise_boolean(value)
    !!HasCustomFields::Helpers::CUSTOM_FIELD_TRUE.include?(value)
  end

  def create_topic(user, action, data)
    if action['custom_title_enabled']
      title = CustomWizard::Builder.fill_placeholders(action['custom_title'], user, data)
    else
      title = data[action['title']]
    end

    if action['post_builder']
      post = CustomWizard::Builder.fill_placeholders(action['post_template'], user, data)
    else
      post = data[action['post']]
    end

    if title
      params = {
        title: title,
        raw: post,
        skip_validations: true
      }

      if action['custom_category_enabled'] &&
        !action['custom_category_wizard_field'] &&
        action['custom_category_user_field_key']

        if action['custom_category_user_field_key'].include?('custom_fields')
          field = action['custom_category_user_field_key'].split('.').last
          category_id = user.custom_fields[field]
        else
          category_id = user.send(action['custom_category_user_field_key'])
        end
      else
        category_id = action['category_id']
      end

      params[:category] = category_id

      topic_custom_fields = {}

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

        unless action['skip_redirect']
          data['redirect_to'] = post.topic.url
        end
      end
    end
  end

  def send_message(user, action, data)
    title = data[action['title']]

    if action['post_builder']
      post = CustomWizard::Builder.fill_placeholders(action['post_template'], user, data)
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
          data['redirect_to'] = post.topic.url
        end
      end
    end
  end

  def update_profile(user, action, data)
    return unless action['profile_updates'].length

    attributes = {}
    custom_fields = {}

    action['profile_updates'].each do |pu|
      value = pu['value']
      custom_field = pu['value_custom']
      user_field = pu['user_field']
      key = pu['key']

      if user_field || custom_field
        custom_fields[user_field || custom_field] = data[key]
      else
        attributes[value.to_sym] = data[key]
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

  def save_submissions(data, final_step)
    if final_step
      data['submitted_at'] = Time.now.iso8601
    end

    if data.present?
      @submissions.pop(1) if @wizard.unfinished?
      @submissions.push(data)
      PluginStore.set("#{@wizard.id}_submissions", @wizard.user.id, @submissions)
    end
  end

  def reset_submissions
    @submissions.pop(1) if @wizard.unfinished?
    PluginStore.set("#{@wizard.id}_submissions", @wizard.user.id, @submissions)
    @wizard.reset
  end
end
