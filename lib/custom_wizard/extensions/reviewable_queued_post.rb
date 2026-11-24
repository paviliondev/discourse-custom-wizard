# frozen_string_literal: true

# When a moderator asks the author to revise a queued wizard topic, core sends the raw post
# and asks the author to post it again with the composer, which loses the wizard's structure.
# If enabled, reopen the wizard prefilled with the author's answers and link to it instead.
module CustomWizardReviewableQueuedPost
  def perform_revise_and_reject_post(performed_by, args)
    draft = custom_wizard_revision_draft
    return super if draft.blank?

    wizard = draft.wizard

    SystemMessage.create(
      target_created_by,
      :custom_wizard_revise_queued_topic,
      **Dsa::AppealInstructions.message_options,
      topic_title: payload["title"],
      reason: args[:revise_custom_reason].presence || args[:revise_reason],
      feedback: args[:revise_feedback],
      wizard_name: wizard.name,
      wizard_url: "#{Discourse.base_url}/w/#{wizard.id.dasherize}",
    )

    StaffActionLogger.new(performed_by).log_post_rejected(self, DateTime.now) if performed_by.staff?
    create_result(:success, :rejected)
  end

  private

  def custom_wizard_revision_draft
    return if !SiteSetting.custom_wizard_enabled || !SiteSetting.custom_wizard_reopen_on_revise
    return if topic.present? || target_created_by.blank?

    wizard_id = payload["wizard_id"]
    submission_id = payload.dig("wizard_custom_fields", "topic", "wizard_submission_id")
    return if wizard_id.blank? || submission_id.blank?

    CustomWizard::Submission.reopen(target_created_by, wizard_id, submission_id)
  rescue StandardError => e
    Discourse.warn_exception(
      e,
      message: "Custom Wizard: failed to reopen wizard for reviewable #{id}",
    )
    nil
  end
end
