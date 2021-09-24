# frozen_string_literal: true

class Jobs::CustomWizardUpdateSubscription < ::Jobs::Scheduled
  every 1.hour

  def execute(args = {})
    CustomWizard::Subscription.update
  end
end
