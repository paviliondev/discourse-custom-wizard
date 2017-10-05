class CustomWizard::StepsController < ApplicationController
  before_action :ensure_logged_in

  def update
    wizard = CustomWizard::Builder.new(current_user, params[:wizard_id]).build
    updater = wizard.create_updater(params[:step_id], params[:fields])
    updater.update

    if updater.success?
      result = success_json
      result.merge!(updater.result) if updater.result
      result[:refresh_required] = true if updater.refresh_required?
      render json: result
    else
      errors = []
      updater.errors.messages.each do |field, msg|
        errors << { field: field, description: msg.join }
      end
      render json: { errors: errors }, status: 422
    end
  end
end
