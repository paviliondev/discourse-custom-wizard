module Jobs
  class RefreshAPIAccessToken < Jobs::Base
    def execute(args)
      CustomWizard::Authorization.refresh_access_token
    end
  end
end
