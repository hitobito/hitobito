# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require_dependency Devise::Engine.root
                                 .join('app', 'controllers', 'devise', 'sessions_controller')
                                 .to_s

class Devise::SessionsController < DeviseController
  layout :devise_layout

  # required to allow api calls
  protect_from_forgery with: :null_session, only: [:new, :create], prepend: true

  respond_to :html
  respond_to :json, only: [:new, :create]

  module Json
    def create
      super do |resource|
        return init_two_factor_auth(resource) if resource.second_factor_required?

        if request.format == :json
          resource.generate_authentication_token! unless resource.authentication_token?
          render json: UserSerializer.new(resource, controller: self)
          return
        end
      end
    end
  end

  module OauthSigninLayout
    private

    def devise_layout
      if params['oauth'] == 'true'
        'oauth'
      else
        'application'
      end
    end
  end

  prepend Json
  prepend OauthSigninLayout

  private
  
  def init_two_factor_auth(resource)
    sign_out(resource)

    session[:pending_two_factor_person_id] = resource.id

    redirect_to second_factor_auth_path(resource), notice: ''
  end

  def second_factor_auth_path(resource)
    case resource.second_factor_auth.to_sym
    when :totp then new_users_totp_path
    end
  end
end
