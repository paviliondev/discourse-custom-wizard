# frozen_string_literal: true
class CustomWizard::StepUpdater
  include ActiveModel::Model

  attr_accessor :refresh_required, :result
  attr_reader :step, :submission

  def initialize(wizard, step, submission)
    @wizard = wizard
    @step = step
    @refresh_required = false
    @submission = submission.with_indifferent_access
    @result = {}
  end

  def update
    if SiteSetting.custom_wizard_enabled &&
       @step.present? &&
       @step.updater.present? &&
       success?

      @step.updater.call(self)

      CustomWizard::UserHistory.create(
        action: CustomWizard::UserHistory.actions[:step],
        actor_id: @wizard.actor_id,
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
