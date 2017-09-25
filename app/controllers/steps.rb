class StepsController < ApplicationController
  before_filter :ensure_logged_in

  def update
    wizard = CustomWizard::Builder.new(current_user, params[:wizard_id]).build
    updater = wizard.create_updater(params[:id], params[:fields])
    updater.update

    if updater.success?
      result = { success: 'OK' }
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
