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
      after_time = validate_after_time
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
      result = { wizard: params }
      result[:after_time] = after_time if after_time
      result
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
    if !@opts[:create]
      wizard = CustomWizard::Wizard.create(params)
    end
    
    new = false
    error = nil
    scheduled = nil
    
    if !@params[:after_time_scheduled] && !wizard[:after_time_scheduled]
      error = 'after_time_need_time'
    else
      scheduled = Time.parse(@params[:after_time_scheduled]).utc
      new = false
      
      if wizard[:after_time_scheduled]
        new = scheduled != Time.parse(wizard[:after_time_scheduled]).utc
      end

      begin
        error = 'after_time_invalid' if new && scheduled < Time.now.utc
      rescue ArgumentError
        error = 'after_time_invalid'
      end
    end
    
    if error
      @error = { type: error }
    else
      {
        new: new,
        scheduled: scheduled
      }
    end
  end
end