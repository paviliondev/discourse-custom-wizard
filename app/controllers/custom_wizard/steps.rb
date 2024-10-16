# frozen_string_literal: true
class CustomWizard::StepsController < ::CustomWizard::WizardClientController
  before_action :ensure_can_update

  def update
    update = update_params.to_h

    update[:fields] = {}
    if params[:fields]
      field_ids = @builder.wizard.field_ids
      params[:fields].each { |k, v| update[:fields][k] = v if field_ids.include? k }
    end

    @builder.build

    updater = @builder.wizard.create_updater(update[:step_id], update[:fields])
    updater.update
    @result = updater.result

    if updater.success?
      wizard_id = update_params[:wizard_id]
      builder = CustomWizard::Builder.new(wizard_id, current_user, guest_id)
      @wizard = builder.build(force: true)

      current_step = @wizard.find_step(update[:step_id])
      current_submission = @wizard.current_submission
      result = {}

      if current_step.conditional_final_step && !current_step.last_step
        current_step.force_final = true
      end

      if current_step.final?
        builder.template.actions.each do |action_template|
          if action_template["run_after"] === "wizard_completion"
            action_result =
              CustomWizard::Action.new(
                action: action_template,
                wizard: @wizard,
                submission: current_submission,
              ).perform

            current_submission = action_result.submission if action_result.success?
          end
        end

        current_submission.save

        if redirect = get_redirect
          updater.result[:redirect_on_complete] = redirect
        end

        @wizard.cleanup_on_complete!

        result[:final] = true
      else
        current_submission.save

        result[:final] = false
        result[:next_step_id] = current_step.next.id
      end

      result.merge!(updater.result) if updater.result.present?
      result[:refresh_required] = true if updater.refresh_required?
      result[:wizard] = ::CustomWizard::WizardSerializer.new(
        @wizard,
        scope: Guardian.new(current_user),
        root: false,
      ).as_json

      render json: result
    else
      errors = []
      updater.errors.messages.each do |field, msg|
        errors << { field: field, description: msg.join(",") }
      end
      render json: { errors: errors }, status: 422
    end
  end

  private

  def ensure_can_update
    raise Discourse::InvalidParameters.new(:wizard_id) if @builder.template.nil?
    raise Discourse::InvalidAccess.new if !@builder.wizard || !@builder.wizard.can_access?

    @step_template = @builder.template.steps.select { |s| s["id"] == update_params[:step_id] }.first
    raise Discourse::InvalidParameters.new(:step_id) if !@step_template
    raise Discourse::InvalidAccess.new if !@builder.check_condition(@step_template)
  end

  def update_params
    @update_params ||
      begin
        params.require(:step_id)
        params.require(:wizard_id)
        params.permit(:wizard_id, :step_id).transform_values { |v| v.underscore }
      end
  end

  def get_redirect
    return @result[:redirect_on_next] if @result[:redirect_on_next].present?

    submission = @wizard.current_submission
    return nil if submission.blank?
    ## route_to set by actions, redirect_on_complete set by actions, redirect_to set at wizard entry
    submission.route_to || submission.redirect_on_complete || submission.redirect_to
  end
end
