class CustomWizard::Api::LogSerializer < ::ApplicationSerializer
  attributes :log_id,
             :time,
             :status,
             :url,
             :error,
             :user_id,
             :username,
             :userpath,
             :name,
             :avatar_template
end
