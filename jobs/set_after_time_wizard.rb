module Jobs
  class SetAfterTimeWizard < ::Jobs::Base
    def execute(args)
      if CustomWizard::Wizard.find(args[:wizard_id])
        user_ids = []

        User.human_users.each do |user|
          if CustomWizard::Wizard.set_wizard_redirect(user, args[:wizard_id])
            user_ids.push(user.id)
          end
        end

        MessageBus.publish "/redirect_to_wizard", args[:wizard_id], user_ids: user_ids
      end
    end
  end
end
