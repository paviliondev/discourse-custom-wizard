module Jobs
  class RefreshApiAccessToken < Jobs::Base
    def execute(args)
      CustomWizard::Authorization.refresh_token(args[:service])
    end
  end
end
