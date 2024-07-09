# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Devise::Hitobito
  class FailureApp < Devise::FailureApp
    def respond
      if request.controller_class.to_s.start_with? "JsonApi::"
        raise JsonApiController::JsonApiUnauthorized
      else
        super
      end
    end
  end
end
