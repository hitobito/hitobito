module Devise::Hitobito
  class FailureApp < Devise::FailureApp
    def respond
      if request.controller_class.to_s.start_with? 'JsonApi::'
        raise JsonApiController::JsonApiUnauthorized
      else
        super
      end
    end
  end
end
