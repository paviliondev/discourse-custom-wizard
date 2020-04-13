class CustomWizard::Builder
  attr_accessor :wizard, :updater, :submissions

  def initialize(wizard_id, user=nil)
    params = CustomWizard::Wizard.find(wizard_id)
    return nil if params.blank?
    
    @wizard = CustomWizard::Wizard.new(params, user)
    @steps = params['steps'] || []
    @actions = params['actions'] || []
    @submissions = @wizard.submissions if user && @wizard
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

  def build(build_opts = {}, params = {})
    return nil if !SiteSetting.custom_wizard_enabled || !@wizard
    return @wizard if !@wizard.can_access?
    
    reset_submissions if build_opts[:reset]

    @steps.each do |step_template|
      @wizard.append_step(step_template['id']) do |step|
        step.title = step_template['title'] if step_template['title']
        step.description = step_template['description'] if step_template['description']
        step.banner = step_template['banner'] if step_template['banner']
        step.key = step_template['key'] if step_template['key']
        step.permitted = true

        if permitted_params = step_template['permitted_params']
          permitted_data = {}

          permitted_params.each do |p|
            pair = p['pairs'].first
            params_key = pair['key'].to_sym
            submission_key = pair['value'].to_sym
            permitted_data[submission_key] = params[params_key] if params[params_key]
          end

          if permitted_data.present?
            current_data = @submissions.last || {}
            save_submissions(current_data.merge(permitted_data), false)
          end
        end

        if (required_data = step_template['required_data']).present?
          has_required_data = true
          pairs = 
          
          required_data.each do |required|
            required['pairs'].each do |pair|
              if pair['key'].blank? || pair['value'].blank?
                has_required_data = false
              end
            end
          end
          
          if has_required_data
            if !@submissions.last
              step.permitted = false
            else
              required_data.each do |required|
                pairs = required['pairs'].map do |p| 
                  p['key'] = @submissions.last[p['key']]
                end
                
                unless CustomWizard::Mapper.new(
                  user: @wizard.user,
                  data: @submissions.last
                ).validate_pairs(pairs)
                  step.permitted = false
                end
              end
            end
            
            if !step.permitted
              if step_template['required_data_message']
                step.permitted_message = step_template['required_data_message'] 
              end
              
              next
            end
          end
        end

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
              validate_field(field, updater, step_template) if field['type'] != 'text_only'
            end
          end
          
          next if updater.errors.any?

          CustomWizard::Builder.step_handlers.each do |handler|
            if handler[:wizard_id] == @wizard.id
              handler[:block].call(self)
            end
          end

          next if updater.errors.any?

          data = updater.fields

          ## if the wizard has data from the previous steps make that accessible to the actions.
          if @submissions && @submissions.last && !@submissions.last.key?("submitted_at")
            submission = @submissions.last
            data = submission.merge(data)
          end
          
          final_step = updater.step.next.nil?
                    
          if @actions.present?
            @actions.each do |action|
              
              if (action['run_after'] === updater.step.id) ||
                 (final_step && (!action['run_after'] || (action['run_after'] === 'wizard_completion')))

                CustomWizard::Action.new(
                  action: action,
                  user: user,
                  data: data,
                  updater: updater
                ).perform
              end
            end
          end
          
          if route_to = data['route_to']
            data.delete('route_to')
          end

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
            if final_step
              updater.result[:redirect_on_complete] = route_to || data['redirect_on_complete']
            elsif route_to
              updater.result[:redirect_on_next] = route_to
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
    
    params[:value] = prefill_field(field_template, step_template) || params[:value]
    
    if field_template['type'] === 'group' && params[:value].present?
      params[:value] = params[:value].first
    end

    if field_template['type'] === 'checkbox'
      params[:value] = standardise_boolean(params[:value])
    end

    if field_template['type'] === 'upload'
      params[:file_types] = field_template['file_types']
    end
    
    if field_template['type'] === 'category' || field_template['type'] === 'tag'
      params[:limit] = field_template['limit']
    end
    
    if field_template['type'] === 'category'
      params[:property] = field_template['property']
    end
        
    if field_template['type'] === 'category'
      @wizard.needs_categories = true
    end
    
    if field_template['type'] === 'group'
      @wizard.needs_groups = true
    end
    
    if (content_inputs = field_template['content']).present?
      content = CustomWizard::Mapper.new(
        inputs: content_inputs,
        user: @wizard.user,
        data: @submissions.last,
        opts: {
          with_type: true
        }
      ).perform
                  
      if content[:type] == 'association'
        content[:result] = content[:result].map do |item|
          { 
            id: item[:key],
            name: item[:value] 
          }
        end
      end
      
      params[:content] = content[:result]
    end
        
    field = step.add_field(params)
  end
  
  def prefill_field(field_template, step_template)
    if (prefill = field_template['prefill']).present?
      CustomWizard::Mapper.new(
        inputs: prefill,
        user: @wizard.user,
        data: @submissions.last
      ).perform
    end
  end

  def validate_field(field, updater, step_template)
    value = updater.fields[field['id']]
    min_length = false
    label = field['label'] || I18n.t("#{field['key']}.label")
    
    if field['required'] && !value
      updater.errors.add(field['id'].to_s, I18n.t('wizard.field.required', label: label))
    end

    if is_text_type(field)
      min_length = field['min_length']
    end

    if min_length && value.is_a?(String) && value.strip.length < min_length.to_i
      updater.errors.add(
        field['id'].to_s,
        I18n.t('wizard.field.too_short', label: label, min: min_length.to_i)
      )
    end

    if is_url_type(field)
      if !check_if_url(value)
        updater.errors.add(field['id'].to_s, I18n.t('wizard.field.not_url', label: label))
      end
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

  def is_text_type(field)
    ['text', 'textarea'].include? field['type']
  end

  def is_url_type(field)
    ['url'].include? field['type']
  end

  def check_if_url(value)
    value =~ URI::regexp
  end

  def standardise_boolean(value)
    ActiveRecord::Type::Boolean.new.cast(value)
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
