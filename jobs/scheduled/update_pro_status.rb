# frozen_string_literal: true

module Jobs
  class UpdateProSubscription < ::Jobs::Scheduled
    every 1.days

    def execute(args)
      CustomWizard::ProSubscription.update
    end
  end
end