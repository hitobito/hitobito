# frozen_string_literal: true

# Copyright (c) 2021, hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https ://github.com/hitobito/hitobito.

class SecondFactorAuthenticationController < ApplicationController
  skip_authorization_check
  before_action :redirect_to_root, unless: :two_factor_authentication_pending_or_signed_in?
  before_action :redirect_on_locked, if: :access_locked?

  def new
    authenticator.prepare_registration! unless authenticator.registered?
  end

  def create
    if authenticator.verify?(params[:second_factor_code])
      sign_in(person) unless person_signed_in?

      flash_msg = notice_flash
      authenticator.register! unless authenticator.registered?

      session.delete(:pending_two_factor_person_id)

      redirect_to root_path, notice: flash_msg
    else
      authenticator.prevent_brute_force!

      redirect_to new_users_second_factor_path, alert: t('second_factor_authentication.flash.failure')
    end
  end

  private

  def authenticator
    @authenticator ||= case authentication_factor
                       when :totp
                         SecondFactorAuthentications::Totp.new(person, session)
                       end
  end

  def person
    @person ||= current_person || pending_two_factor_person
  end

  def authentication_factor
    @authentication_factor ||= params[:second_factor].to_sym
  end

  def redirect_to_root
    redirect_to root_path
  end

  def redirect_on_locked
    reset_session
    redirect_to root_path, alert: t('devise.failure.locked')
  end

  def notice_flash
    message = authenticator.registered? ? 'signed_in' : 'registered' 
    t("second_factor_authentication.flash.success.#{message}")
  end

  def access_locked?
    person.access_locked?
  end

  def authenticate?
    false
  end

  def two_factor_authentication_pending_or_signed_in?
    two_factor_authentication_pending? || person_signed_in?
  end
end
