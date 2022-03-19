# frozen_string_literal: true

#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Devise::Hitobito::SessionsController < Devise::SessionsController
  layout :devise_layout
  include ::TwoFactor

  # required to allow api calls
  protect_from_forgery with: :null_session, only: [:new, :create], prepend: true

  respond_to :html
  respond_to :json, only: [:new, :create]

  before_action :reset_two_factor_authentication,
                if: :two_factor_authentication_pending?,
                only: [:new]

  def create
    super do |resource|
      if second_factor_required?(resource)
        # we pass the value of after_sign_in_path_for to init_two_factor_auth
        # so that we can save it to the session again after sign_out is performed
        # there
        after_2fa_path = after_sign_in_path_for(resource)
        return init_two_factor_auth(resource, after_2fa_path)
      end

      if request.format == :json
        resource.generate_authentication_token! unless resource.authentication_token?
        render json: UserSerializer.new(resource, controller: self)
        return
      end
    end
  end

  private

  def second_factor_required?(resource)
    resource.is_a?(Person) && resource.second_factor_required?
  end

  def devise_layout
    if params['oauth'] == 'true'
      'oauth'
    else
      'application'
    end
  end
end
