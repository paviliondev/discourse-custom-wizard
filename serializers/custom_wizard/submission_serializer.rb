# frozen_string_literal: true
class CustomWizard::SubmissionSerializer < ApplicationSerializer
  attributes :id,
             :username,
             :fields,
             :submitted_at

  def username
    object.user.present? ?
    object.user.username :
    I18n.t('admin.wizard.submission.no_user', user_id: object.user_id)
  end
end
