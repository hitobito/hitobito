# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Concerns
  module Authenticatable
    extend ActiveSupport::Concern

    included do
      helper_method :current_user

      before_action :authenticate_person!
      check_authorization unless: :devise_controller?
    end


    private

    def current_person
      @current_person ||= super.tap do |user|
        Person::PreloadGroups.for(user)
      end
    end

    def current_user
      current_person
    end

    # invoke this method where required with prepend_before_action
    def authenticate_person_from_onetime_token!
      token = Devise.token_generator.digest(Person, :reset_password_token, params[:onetime_token])
      user = Person.find_or_initialize_with_error_by(:reset_password_token, token)

      if user.persisted? && user.reset_password_period_valid?
        user.clear_reset_password_token!
        sign_in user
      end
    end

    def authenticate_person!(*args)
      # Set the authentication token params if not already present,
      params[:user_token] = params[:user_token].presence || request.headers['X-User-Token'].presence
      params[:user_email] = params[:user_email].presence || request.headers['X-User-Email'].presence

      user = params[:user_email] && Person.find_by_email(params[:user_email])

      # Notice how we use Devise.secure_compare to compare the token
      # in the database with the token given in the params, mitigating
      # timing attacks.
      if user && Devise.secure_compare(user.authentication_token, params[:user_token])
        # Sign in using token should not be tracked by Devise trackable
        # See https://github.com/plataformatec/devise/issues/953
        request.env["devise.skip_trackable"] = true

        # Notice the store option defaults to false, so the entity
        # is not actually stored in the session and a token is needed
        # for every request. That behaviour can be configured through
        # the sign_in_token option.
        sign_in user, store: false
      else
        super(*args)
      end
    end
  end
end
