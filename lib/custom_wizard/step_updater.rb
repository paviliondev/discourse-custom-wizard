class CustomWizard::StepUpdater
  include ActiveModel::Model

  attr_accessor :refresh_required, :submission, :result, :step

  def initialize(current_user, wizard, step, submission)
    @current_user = current_user
    @wizard = wizard
    @step = step
    @refresh_required = false
    @submission = submission.to_h.with_indifferent_access
    @result = {}
  end

  def update
    if SiteSetting.custom_wizard_enabled &&
       @step.present? &&
       @step.updater.present? &&
       success?

      @step.updater.call(self)

      UserHistory.create(
        action: UserHistory.actions[:custom_wizard_step],
        acting_user_id: @current_user.id,
        context: @wizard.id,
        subject: @step.id
      )
    else
      false
    end
  end

  def success?
    @errors.blank?
  end

  def refresh_required?
    @refresh_required
  end

  def validate
    CustomWizard::UpdateValidator.new(self).perform
  end
end
