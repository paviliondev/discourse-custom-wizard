module Jobs
  class RefreshApiAccessToken < ::Jobs::Base
    def execute(args)
      CustomWizard::Api::Authorization.get_token(args[:name], refresh: true)
    end
  end
end
