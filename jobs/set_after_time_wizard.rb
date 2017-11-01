module Jobs
  class SetAfterTimeWizard < Jobs::Base
    def execute(args)
      if PluginStoreRow.exists?(plugin_name: 'custom_wizard', key: args[:wizard_id])
        user_ids = []
        User.human_users.each do |u|
          u.custom_fields['redirect_to_wizard'] = args[:wizard_id]
          u.save_custom_fields(true)
          user_ids.push(u.id)
        end
        MessageBus.publish "/redirect_to_wizard", args[:wizard_id], user_ids: user_ids
      end
    end
  end
end
