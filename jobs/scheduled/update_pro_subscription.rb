# frozen_string_literal: true

class CustomWizard::UpdateProSubscription < ::Jobs::Scheduled
  every 1.hour

  def execute(args)
    CustomWizard::Pro.update_subscription
  end
end