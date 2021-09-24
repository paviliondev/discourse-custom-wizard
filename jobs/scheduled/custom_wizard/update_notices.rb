# frozen_string_literal: true

class Jobs::CustomWizardUpdateNotices < ::Jobs::Scheduled
  every 5.minutes

  def execute(args = {})
    CustomWizard::Notice.update
  end
end