module Jobs
  class SetAfterTimeWizard < ::Jobs::Base
    def execute(args)
      if SiteSetting.custom_wizard_enabled
        wizard = CustomWizard::Wizard.create(args[:wizard_id])
        
        if wizard && wizard.after_time
          user_ids = []

          User.human_users.each do |user|
            if CustomWizard::Wizard.set_wizard_redirect(wizard.id, user)
              user_ids.push(user.id)
            end
          end

          MessageBus.publish "/redirect_to_wizard", wizard.id, user_ids: user_ids
        end
      end
    end
  end
end
