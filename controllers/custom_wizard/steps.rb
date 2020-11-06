class CustomWizard::StepsController < ::ApplicationController
  before_action :ensure_logged_in
  before_action :ensure_can_update

  def update
    params.require(:step_id)
    params.require(:wizard_id)
    
    wizard = @builder.build
    step = wizard.steps.select { |s| s.id == update_params[:step_id] }.first

    raise Discourse::InvalidParameters.new(:step_id) if !step
    
    update = update_params.to_h
  
    update[:fields] = {}
    if params[:fields]
      field_ids = step.fields.map(&:id)
      params[:fields].each do |k, v|
        update[:fields][k] = v if field_ids.include? k
      end
    end
    
    updater = wizard.create_updater(update[:step_id], update[:fields])
    updater.update
        
    if updater.success?
      result = success_json
      result.merge!(updater.result) if updater.result
      result[:refresh_required] = true if updater.refresh_required?
      
      render json: result
    else
      errors = []
      updater.errors.messages.each do |field, msg|
        errors << { field: field, description: msg.join(',') }
      end
      render json: { errors: errors }, status: 422
    end
  end
  
  private
  
  def ensure_can_update
    @builder = CustomWizard::Builder.new(
      update_params[:wizard_id].underscore,
      current_user
    )
    
    if @builder.nil?
      raise Discourse::InvalidParameters.new(:wizard_id)
    end
    
    if !@builder.wizard || !@builder.wizard.can_access?
      raise Discourse::InvalidAccess.new
    end
  end
  
  def update_params
    params.permit(:wizard_id, :step_id)
  end
end
