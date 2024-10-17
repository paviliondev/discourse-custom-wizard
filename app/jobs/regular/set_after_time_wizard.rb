# frozen_string_literal: true
module Jobs
  class SetAfterTimeWizard < ::Jobs::Base
    def execute(args)
      if SiteSetting.custom_wizard_enabled
        @wizard = CustomWizard::Wizard.create(args[:wizard_id])

        if @wizard && @wizard.after_time
          user_ids = []

          target_users.each do |user|
            user_ids.push(user.id) if CustomWizard::Wizard.set_after_time_redirect(@wizard.id, user)
          end

          CustomWizard::Template.clear_cache_keys

          MessageBus.publish "/redirect_to_wizard", @wizard.id, user_ids: user_ids
        end
      end
    end

    def target_users
      users = []

      if @wizard.after_time_groups.exists?
        @wizard.after_time_groups.each { |group| users += group.users }
      else
        users = User.human_users
      end

      users
    end
  end
end
