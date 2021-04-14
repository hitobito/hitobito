# frozen_string_literal: true

# Copyright (c) 2021, hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https ://github.com/hitobito/hitobito.

class TotpController < ApplicationController
  skip_authorization_check
  before_action :redirect_to_root, unless: :two_factor_authentication_pending_or_signed_in?
  before_action :redirect_on_locked, if: :access_locked?

  def new
    session[:pending_totp_secret] ||= generate_secret unless person.totp_registered?
  end

  def create
    if otp.verify(params[:totp_code]).present?
      sign_in(person) unless person_signed_in?

      flash_msg = notice_flash
      register_totp! unless person.totp_registered?

      session.delete(:pending_two_factor_person_id)

      redirect_to root_path, notice: flash_msg
    else
      prevent_brute_force!

      redirect_to new_users_totp_path, alert: t('totp.flash.failure')
    end
  end

  private

  def person
    @person ||= current_person || pending_two_factor_person
  end

  def authenticate?
    false
  end

  def register_totp!
    person.totp_secret = session.delete(:pending_totp_secret)
    person.second_factor_auth = :totp
    person.save!
  end

  def prevent_brute_force!
    person.increment_failed_attempts
    if person.failed_attempts > Person.maximum_attempts
      person.lock_access!
    end
  end

  def generate_secret
    People::OneTimePassword.generate_secret
  end

  def otp
    People::OneTimePassword.new(secret)
  end

  def secret
    person.totp_registered? ? person.totp_secret : session[:pending_totp_secret] 
  end

  def access_locked?
    person.access_locked?
  end

  def redirect_to_root
    redirect_to root_path
  end

  def redirect_on_locked
    reset_session
    redirect_to root_path, alert: t('devise.failure.locked')
  end

  def notice_flash
    message = person.totp_registered? ? 'signed_in' : 'registered' 
    t("totp.flash.success.#{message}")
  end

  def two_factor_authentication_pending_or_signed_in?
    two_factor_authentication_pending? || person_signed_in?
  end
end
