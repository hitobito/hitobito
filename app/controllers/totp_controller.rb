# frozen_string_literal: true


class TotpController < ApplicationController
  # before_action :redirect_to_root, unless: :two_factor_authentication_pending?
  skip_authorization_check

  def new
    session[:pending_totp_secret] ||= generate_secret unless person.totp_registered?

  end

  def create
    if otp.verify(params[:totp_code]).present?
      sign_in(person) unless person_signed_in?

      unless person.totp_registered?
        person.totp_secret = session.delete(:pending_totp_secret)
      end

      session.delete(:pending_two_factor_person_id)

      person.save!

      redirect_to root_path
    else
      redirect_to new_users_totp_path, alert: 'wrong'
    end
  end

  private

  def person
    @person ||= pending_two_factor_person
  end

  def authenticate?
    false
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
end
