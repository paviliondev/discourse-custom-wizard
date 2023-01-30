# frozen_string_literal: true

class CustomWizard::RealtimeValidationsController < ::ApplicationController
  def validate
    klass_str = "CustomWizard::RealtimeValidation::#{validation_params[:type].camelize}"
    result = klass_str.constantize.new(current_user).perform(validation_params)
    render_serialized(result.items, "#{klass_str}Serializer".constantize, result.serializer_opts)
  end

  private

  def validation_params
    params.require(:type)
    settings = ::CustomWizard::RealtimeValidation.types[params[:type].to_sym]
    params.require(settings[:required_params]) if settings[:required_params].present?
    params
  end
end
