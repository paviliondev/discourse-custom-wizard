class CustomWizard::SubmissionSerializer
  attributes :id,
             :username,
             :fields,
             :redirect_to,
             :submitted_at

  def username
    object.user.deleted ?
    I18n.t('admin.wizard.submission.no_user', user_id: object.user.id) :
    object.user.username
  end
end