# frozen_string_literal: true

module CustomWizardGuardian
  def can_edit_topic?(topic)
    wizard_can_edit_topic?(topic) || super
  end

  def wizard_can_edit_topic?(topic)
    created_by_wizard = !!topic.wizard_submission_id
    (
      is_my_own?(topic) &&
      created_by_wizard &&
      can_see_topic?(topic) &&
      can_create_post_on_topic?(topic)
    )
  end
end
