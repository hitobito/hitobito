# frozen_string_literal: true

# Copyright (c) 2021, hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https ://github.com/hitobito/hitobito.

class SecondFactorAuthenticationController < ApplicationController
  include Devise::Controllers::Rememberable
  include ::TwoFactor

  skip_authorization_check

  before_action :redirect_on_locked, if: :access_locked?
  before_action :redirect_to_root, unless: :allowed?

  helper_method :authentication_factor, :person, :secret

  def new
    authenticator.prepare_registration! unless authenticator.registered?
  end

  def create
    if authenticator.verify?(params[:second_factor_code])
      unless authenticator.registered?
        authenticator.register!
        flash_msg = registered_flash
      end

      return_path = session.delete(:after_2fa_path)

      unless person_signed_in?
        remember_me(person) if remember_me?

        reset_session

        sign_in(person)
      end

      redirect_to return_path || root_path, notice: flash_msg
    else
      authenticator.prevent_brute_force!

      redirect_to new_users_second_factor_path,
                  alert: t('second_factor_authentication.flash.failure')
    end
  end

  private

  def authenticator
    @authenticator ||= {
      'totp' => Authenticatable::TwoFactors::Totp
    }[authentication_factor]&.new(person, session)
  end

  def person
    @person ||= current_person || pending_two_factor_person
  end

  def secret
    @secret ||= authenticator.secret
  end

  def authentication_factor
    @authentication_factor ||= session[:pending_second_factor_authentication] ||
                                 params[:second_factor]
  end

  def redirect_to_root
    redirect_to root_path
  end

  def redirect_on_locked
    reset_session
    redirect_to root_path, alert: t('devise.failure.locked')
  end

  def registered_flash
    t('second_factor_authentication.flash.success.registered')
  end

  def access_locked?
    person&.access_locked?
  end

  def authenticate?
    false
  end

  def two_factor_authentication_pending_or_signed_in?
    two_factor_authentication_pending? || person_signed_in?
  end

  def second_factor_registered_and_signed_in?
    authenticator.registered? && person_signed_in?
  end
  
  def allowed?
    authenticator.present? &&
      !second_factor_registered_and_signed_in? &&
      two_factor_authentication_pending_or_signed_in?
  end
end
