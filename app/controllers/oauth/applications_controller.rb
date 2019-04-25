module Oauth
  class ApplicationsController < CrudController

    self.permitted_attrs = [:name, :redirect_uri, :scopes, :confidential]

    def self.model_class
      Oauth::Application
    end
  end
end
