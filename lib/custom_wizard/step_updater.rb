class CustomWizard::StepUpdater
  include ActiveModel::Model

  attr_accessor :refresh_required, :fields, :result, :step

  def initialize(current_user, wizard, step, fields)
    @current_user = current_user
    @wizard = wizard
    @step = step
    @refresh_required = false
    @fields = fields
    @result = {}
  end

  def update
    @step.updater.call(self) if @step.present? && @step.updater.present?

    if success?
      UserHistory.create(action: UserHistory.actions[:custom_wizard_step],
                         acting_user_id: @current_user.id,
                         context: @wizard.id,
                         subject: @step.id)
    end
  end

  def success?
    @errors.blank?
  end

  def refresh_required?
    @refresh_required
  end
end
