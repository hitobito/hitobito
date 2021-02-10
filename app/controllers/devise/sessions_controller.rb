# frozen_string_literal: true

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require_dependency Devise::Engine.root
                                 .join('app', 'controllers', 'devise', 'sessions_controller')
                                 .to_s

class Devise::SessionsController < DeviseController

  # required to allow api calls
  protect_from_forgery with: :null_session, only: [:new, :create], prepend: true

  respond_to :html
  respond_to :json, only: [:new, :create]

  module Json
    def create
      super do |resource|
        if request.format == :json
          resource.generate_authentication_token! unless resource.authentication_token?
          render json: UserSerializer.new(resource, controller: self)
          return
        end
      end
    end
  end

  prepend Json

end
