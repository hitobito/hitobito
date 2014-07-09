# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require_dependency Devise::Engine.root.
                                  join('app', 'controllers', 'devise', 'sessions_controller').
                                  to_s

class Devise::SessionsController < DeviseController

  respond_to :html
  respond_to :json, only: [:new, :create]

  def create_with_json
    create_without_json do |resource|
      if request.format == :json
        resource.generate_authentication_token! unless resource.authentication_token?
        render json: UserSerializer.new(resource, controller: self)
        return
      end
    end
  end
  alias_method_chain :create, :json

end
