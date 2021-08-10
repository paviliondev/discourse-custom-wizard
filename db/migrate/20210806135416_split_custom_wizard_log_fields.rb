class SplitCustomWizardLogFields < ActiveRecord::Migration[6.1]
  def change
    reversible do |dir|
      dir.up do
          # separate wizard/action/user into their own keys

          wizard_logs = PluginStoreRow.where("
            plugin_name = 'custom_wizard_log' 
          ")

          if wizard_logs.exists?
            wizard_logs.each do |row|
              begin
                log_json = JSON.parse(row.value)
              rescue TypeError, JSON::ParserError
                next
              end

              # first three keys are wizard/action/user

              if log_json.key?('message')
                attr_strs = log_json['message'].split('; ', 4)

                log_json['message'] = attr_strs.pop

                attr_strs.each do |attr_str|
                  key, value = attr_str.split(': ')
                  log_json[key] = value
                end

                row.value = log_json.to_json
                row.save

              end
            end
          end
      end
      dir.down do
        wizard_logs = PluginStoreRow.where("
          plugin_name = 'custom_wizard_log' 
        ")

        if wizard_logs.exists?
          wizard_logs.each do |row|
            begin
              log_json = JSON.parse(row.value)
            rescue TypeError, JSON::ParserError
              next
            end

            # concatenate wizard/action/user to start of message
            prefixes = log_json.extract!('wizard', 'action', 'user')

            message_prefix = prefixes.map{|k,v| "#{k}: #{v}"}.join('; ')

            if log_json.key?('message')
              log_json['message'] = "#{message_prefix}; #{log_json['message']}"
            else
              log_json['message'] = message_prefix
            end

            row.value = log_json.to_json
            row.save

          end
        end
      end
    end
  end
end
