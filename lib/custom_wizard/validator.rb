class CustomWizard::Validator
  
  def initialize(params, opts={})
    @params = params
    @opts = opts
    @error = nil
  end
  
  def perform
    params = @params
            
    check_id(params, :wizard)
    check_required(params, :wizard)
    check_depdendent(params, :wizard)
    
    after_time = nil
        
    if !@error && @params[:after_time]
      validate_after_time
    end
            
    if !@error
      params[:steps].each do |step|
        check_required(step, :step)
        check_depdendent(step, :step)
        break if @error.present?
        
        if params[:fields].present?
          params[:fields].each do |field|
            check_required(field, :field)
            check_depdendent(field, :field)
            break if @error.present?
          end
        end
      end
      
      if params[:actions].present?
        params[:actions].each do |action|
          check_required(action, :action)
          check_depdendent(action, :action)
          break if @error.present?
        end
      end
    end
        
    if @error
      { error: @error }
    else
      { wizard: params }
    end
  end
  
  def self.required
    {
      wizard: ['id', 'name', 'steps'],
      step: ['id'],
      field: ['id', 'type'],
      action: ['id', 'type']
    }
  end
  
  def self.dependent
    {
      wizard: {
        after_time: 'after_time_scheduled'
      },
      step: {},
      field: {},
      action: {}
    }
  end
  
  private
  
  def check_required(object, type)
    CustomWizard::Validator.required[type].each do |property|      
      if object[property].blank?
        @error = {
          type: 'required',
          params: { type: type, property: property }
        }
      end
    end
  end
  
  def check_depdendent(object, type)
    CustomWizard::Validator.dependent[type].each do |property, dependent|
      if object[property] && object[dependent].blank?
        @error = {
          type: 'dependent',
          params: { property: property, dependent: dependent }
        }
      end
    end
  end
  
  def check_id(object, type)
    if type === :wizard && @opts[:create] && CustomWizard::Wizard.exists?(object[:id])
      @error = {
        type: 'conflict',
        params: { type: type, property: 'id', value: object[:id] }
      }
    end
  end
  
  def validate_after_time    
    wizard = CustomWizard::Wizard.create(@params[:id]) if !@opts[:create]
    current_time = wizard.present? ? wizard.after_time_scheduled : nil
    new_time = @params[:after_time_scheduled]
    
    begin
      active_time = Time.parse(new_time.present? ? new_time : current_time).utc
    rescue ArgumentError
      invalid_time = true
    end

    if invalid_time || active_time.blank? || active_time < Time.now.utc
      @error = { type: 'after_time' }
    end
  end
end