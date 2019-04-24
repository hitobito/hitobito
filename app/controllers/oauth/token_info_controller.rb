module Oauth
  class TokenInfoController < Doorkeeper::ApplicationMetalController
    def show
      if doorkeeper_token && doorkeeper_token.accessible?
        render json: doorkeeper_token.merge(person_attributes), status: :ok
      else
        error = OAuth::ErrorResponse.new(name: :invalid_request)
        response.headers.merge!(error.headers)
        render json: error.body, status: error.status
      end
    end

    def person_attributes
      {}
    end
  end
end
