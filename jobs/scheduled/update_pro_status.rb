# frozen_string_literal: true

class CustomWizard::UpdateProSubscription < ::Jobs::Scheduled
  every 10.minutes

  def execute(args)
    CustomWizard::ProSubscription.update
  end
end