# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Authenticatable
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :origin_user

    before_action :authenticate_person!, if: :authenticate?
    check_authorization if: :authorize?
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

  # TODO: can we somehow use this dynamic user as a true substitute instead of
  #       passing it explicitly at various places
  def service_token_user
    current_ability.token.dynamic_user if current_ability.is_a?(TokenAbility)
  end

  def origin_user
    return unless session[:origin_user]

    Person.find(session[:origin_user])
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

  def prepare_authorization_via_shared_access_token
    if current_person && params.key?(:shared_access_token)
      current_person.shared_access_token = params[:shared_access_token]
    end
  end

  def doorkeeper_sign_in
    token = token_authentication.oauth_token
    return unless token&.acceptable? :api

    user = Person.find(token.resource_owner_id)
    sign_in user, store: false
  end

  def authenticate_person!(*args)
    user_sign_in || service_token_sign_in || doorkeeper_sign_in || super(*args)
  end

  def user_sign_in
    user = token_authentication.user_from_token
    return unless user

    # Sign in using token should not be tracked by Devise trackable
    # See https://github.com/plataformatec/devise/issues/953
    request.env['devise.skip_trackable'] = true

    # Notice the store option defaults to false, so the entity
    # is not actually stored in the session and a token is needed
    # for every request. That behaviour can be configured through
    # the sign_in_token option.
    sign_in user, store: false
  end

  def service_token_sign_in
    service_token = token_authentication.service_token
    return unless service_token

    request.env['devise.skip_trackable'] = true
    service_token.update(last_access: Time.zone.now)
    sign_in service_token, store: false
  end

  def token_authentication
    @token_authentication ||= Authenticatable::Tokens.new(request, params)
  end

  def authorize?
    !devise_controller? && !doorkeeper_controller?
  end

  def authenticate?
    !doorkeeper_controller?
  end

  def doorkeeper_controller?
    is_a?(Doorkeeper::ApplicationController)
  end
end
