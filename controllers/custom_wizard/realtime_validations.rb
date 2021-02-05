class CustomWizard::RealtimeValidationsController < ::ApplicationController
  def validate
    params.require(:validation)
    params.require(::CustomWizard::RealtimeValidation.types[params[:validation].to_sym][:required_params])

    render_json_dump(::CustomWizard::RealtimeValidation.send(params[:validation], params, current_user))
  end
end
