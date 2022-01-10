class Authenticatable::SecondFactors::Totp < Authenticatable::SecondFactor
  def verify?(code)
    otp.verify(code).present?
  end

  def prepare_registration!
    session[:pending_totp_secret] ||= generate_secret
  end

  def register!
    person.totp_secret = session.delete(:pending_totp_secret)
    person.second_factor_auth = :totp
    person.save!
  end

  def otp
    @otp ||= People::OneTimePassword.new(secret)
  end

  def secret
    person.totp_registered? ? person.totp_secret : session[:pending_totp_secret] 
  end

  def registered?
    person.totp_registered?
  end

  private

  def generate_secret
    People::OneTimePassword.generate_secret
  end
end
