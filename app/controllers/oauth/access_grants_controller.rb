module Oauth
  class AccessGrantsController < CrudController
    def destroy
      super(location: oauth_application_path(entry.application))
    end

    def self.model_class
      Oauth::AccessGrant
    end
  end
end
