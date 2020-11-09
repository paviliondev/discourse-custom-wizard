module Jobs
  class ClearAfterTimeWizard < ::Jobs::Base
    sidekiq_options queue: 'critical'

    def execute(args)
      User.human_users.each do |u|
        if u.custom_fields['redirect_to_wizard'] == args[:wizard_id]
          u.custom_fields.delete('redirect_to_wizard')
          u.save_custom_fields(true)
        end
      end
    end
  end
end
