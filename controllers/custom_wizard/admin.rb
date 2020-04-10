class CustomWizard::AdminController < ::ApplicationController
  before_action :ensure_logged_in
  before_action :ensure_admin

  def index
    render nothing: true
  end

  def field_types
    render json: { types: CustomWizard::Field.types }
  end

  def save    
    result = build_wizard

    if result[:error]
      render json: { error: result[:error] }
    else
      wizard = result[:wizard]
      existing_wizard = result[:existing_wizard]
      
      ActiveRecord::Base.transaction do
        PluginStore.set('custom_wizard', wizard["id"], wizard)
        
        if wizard['after_time'] && result[:new_after_time]
          Jobs.cancel_scheduled_job(:set_after_time_wizard, wizard_id: wizard['id'])
          Jobs.enqueue_at(after_time_scheduled, :set_after_time_wizard, wizard_id: wizard['id'])
        end

        if existing_wizard && existing_wizard['after_time'] && !wizard['after_time']
          Jobs.cancel_scheduled_job(:set_after_time_wizard, wizard_id: wizard['id'])
          Jobs.enqueue(:clear_after_time_wizard, wizard_id: wizard['id'])
        end
      end
      
      render json: success_json.merge(wizard: wizard)
    end
  end

  def remove
    params.require(:id)

    wizard = PluginStore.get('custom_wizard', params[:id])

    if wizard['after_time']
      Jobs.cancel_scheduled_job(:set_after_time_wizard)
      Jobs.enqueue(:clear_after_time_wizard, wizard_id: wizard['id'])
    end

    PluginStore.remove('custom_wizard', params[:id])

    render json: success_json
  end

  def find_wizard
    params.require(:wizard_id)

    wizard = PluginStore.get('custom_wizard', params[:wizard_id].underscore)

    render json: success_json.merge(wizard: wizard)
  end

  def custom_wizards
    rows = PluginStoreRow.where(plugin_name: 'custom_wizard').order(:id)

    wizards = [*rows].map { |r| CustomWizard::Template.new(r.value) }

    render json: success_json.merge(wizards: wizards)
  end

  def submissions
    params.require(:wizard_id)

    rows = PluginStoreRow.where(plugin_name: "#{params[:wizard_id]}_submissions").order('id DESC')

    all_submissions = [*rows].map do |r|
      submissions = ::JSON.parse(r.value)

      if user = User.find_by(id: r.key)
        username = user.username
      else
        username = I18n.t('admin.wizard.submissions.no_user', id: r.key)
      end

      submissions.map { |s| { username: username }.merge!(s.except("redirect_to")) }
    end.flatten

    render json: success_json.merge(submissions: all_submissions)
  end
  
  private
  
  def wizard_params
    params.require(:wizard)
    params[:wizard]
  end
  
  def required_properties
    {
      wizard: ['id', 'name', 'steps'],
      step: ['id'],
      field: ['id', 'type'],
      action: ['id', 'type']
    }
  end
  
  def dependent_properties
    {
      wizard: {
        after_time: 'after_time_scheduled'
      },
      step: {},
      field: {},
      action: {}
    }
  end
    
  def check_required(object, type, error)
    required_properties[type].each do |property|      
      if object[property].blank?
        error = {
          type: 'required',
          params: { type: type, property: property }
        }
      end
    end
    
    error
  end
  
  def check_depdendent(object, type, error)
    dependent_properties[type].each do |property, dependent|
      if object[property] && object[dependent].blank?
        error = {
          type: 'dependent',
          params: { property: property, dependent: dependent }
        }
      end
    end

    error
  end
  
  def validate_wizard(wizard)
    error = nil
    
    error = check_required(wizard, :wizard, error)
    error = check_depdendent(wizard, :wizard, error)
        
    if !error
      wizard['steps'].each do |step|
        error = check_required(step, :step, error)
        error = check_depdendent(step, :step, error)
        break if error.present?
        
        if step['fields'].present?
          step['fields'].each do |field|
            error = check_required(field, :field, error)
            error = check_depdendent(field, :field, error)
            break if error.present?
          end
        end
      end
      
      if wizard['actions'].present?
        wizard['actions'].each do |action|
          error = check_required(action, :action, error)
          error = check_depdendent(action, :action, error)
          break if error.present?
        end
      end
    end
    
    if error
      { error: error }
    else
      { success: true }
    end
  end
  
  def validate_after_time(wizard, existing_wizard)
    new = false
    error = nil
    
    if wizard["after_time"]
      if !wizard["after_time_scheduled"] && !existing_wizard["after_time_scheduled"]
        error = 'after_time_need_time'
      else
        after_time_scheduled = Time.parse(wizard["after_time_scheduled"]).utc

        new = existing_wizard['after_time_scheduled'] ?
              after_time_scheduled != Time.parse(existing_wizard['after_time_scheduled']).utc :
              true

        begin
          error = 'after_time_invalid' if new && after_time_scheduled < Time.now.utc
        rescue ArgumentError
          error = 'after_time_invalid'
        end
      end
    end
    
    if error
      { error: { type: error } }
    else
      { new: new }
    end
  end
  
  def build_wizard
    wizard = ::JSON.parse(wizard_params)
    existing_wizard = PluginStore.get('custom_wizard', wizard['id']) || {}
    
    validation = validate_wizard(wizard)
    return validation if validation[:error]
    
    after_time_validation = validate_after_time(wizard, existing_wizard)
    return after_time_validation if after_time_validation[:error]
      
    wizard['steps'].each do |step|
      if step['raw_description']
        step['description'] = PrettyText.cook(step['raw_description'])
      end
    end

    {
      wizard: wizard,
      existing_wizard: existing_wizard,
      new_after_time: after_time_validation[:new]
    }
  end
end
