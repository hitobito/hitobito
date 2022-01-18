# frozen_string_literal: true
#
#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Authenticatable::TwoFactors::Totp < Authenticatable::TwoFactor
  def verify?(code)
    otp.verify(code).present?
  end

  def prepare_registration!
    session[:pending_totp_secret] ||= generate_secret
  end

  def register!
    person.two_fa_secret = session.delete(:pending_totp_secret)
    person.two_factor_authentication = :totp
    person.save!(validate: false)
  end

  def registered?
    person&.two_factor_authentication_registered?
  end

  def secret
    person.two_factor_authentication_registered? ?
      person.two_fa_secret :
      session[:pending_totp_secret] 
  end

  private

  def generate_secret
    People::OneTimePassword.generate_secret
  end

  def otp
    @otp ||= People::OneTimePassword.new(secret)
  end
end
