# frozen_string_literal: true

class CustomWizard::RealtimeValidationsController < ::ApplicationController
  def validate
    params.require(:validation)
    params.require(::CustomWizard::RealtimeValidation.types[params[:validation].to_sym][:required_params])

    result = ::CustomWizard::RealtimeValidation.send(params[:validation], params, current_user)
    render_serialized(result[:items], result[:serializer], result[:opts])
  end
end
