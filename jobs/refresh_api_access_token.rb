module Jobs
  class RefreshApiAccessToken < Jobs::Base
    def execute(args)
      CustomWizard::Api::Authorization.refresh_token(args[:name])
    end
  end
end
