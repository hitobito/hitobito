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

      before_filter :authenticate_person!
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

    def authenticate_person_from_token!
      token = Devise.token_generator.digest(Person, :reset_password_token, params[:onetime_token])
      user = Person.find_or_initialize_with_error_by(:reset_password_token, token)

      if user.persisted? && user.reset_password_period_valid?
        user.clear_reset_password_token!
        sign_in user
      end
    end

  end
end