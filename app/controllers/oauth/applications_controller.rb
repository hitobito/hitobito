module Oauth
  class ApplicationsController < CrudController

    self.permitted_attrs = [:name, :redirect_uri, :scopes, :confidential]


    def self.model_class
      Oauth::Application
    end

    private

    # def find_entry
    #   model_scope.includes(access_grants: :person, access_tokens: :person).find(params[:id])
    # end
  end

end
