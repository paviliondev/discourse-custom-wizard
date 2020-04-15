class CustomWizard::StepsController < ::ApplicationController
  before_action :ensure_logged_in

  def update
    params.require(:step_id)
    params.require(:wizard_id)
    field_ids = CustomWizard::Wizard.field_ids(params[:wizard_id], params[:step_id])

    permitted = params.permit(:wizard_id, :step_id)
    if params[:fields]
      permitted[:fields] = params[:fields].select { |k, v| field_ids.include? k }
      permitted.permit!
    end

    wizard = CustomWizard::Builder.new(permitted[:wizard_id].underscore, current_user).build
    updater = wizard.create_updater(permitted[:step_id], permitted[:fields])
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
end
