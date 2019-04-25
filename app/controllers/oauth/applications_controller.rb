module Oauth
  class ApplicationsController < CrudController

    self.permitted_attrs = [:name, :redirect_uri, :confidential, scopes: []]

    def self.model_class
      Oauth::Application
    end

    def permitted_params
      super.tap do |attrs|
        attrs[:scopes] = Array(attrs.delete(:scopes)).join(' ')
      end
    end
  end
end
