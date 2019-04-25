module Oauth
  class AccessTokensController < CrudController
    def destroy
      super(location: oauth_application_path(entry.application))
    end

    def self.model_class
      Oauth::AccessToken
    end
  end
end
