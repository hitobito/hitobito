# frozen_string_literal: true

class People::OneTimePassword

  def self.generate_secret
    ROTP::Base32.random
  end

  def initialize(totp_secret, person: nil)
    raise 'totp_secret cant be blank' if totp_secret.blank?

    @totp_secret = totp_secret
    @person = person
  end

  def provisioning_uri
    authenticator.provisioning_uri(person.email)
  end

  def provisioning_qr_code
    RQRCode::QRCode.new(provisioning_uri).as_png(module_px_size: 3)
  end

  def verify(token)
    return false if totp_secret.blank?

    authenticator.verify(token)
  end

  private

  attr_accessor :totp_secret, :person

  def secret
    base = "#{base_secret}-#{totp_secret}"
    sha = Digest::SHA512.hexdigest(base)
    base32_encode(sha)
  end

  def authenticator
    # TODO add correct issuer
    ROTP::TOTP.new(secret, issuer: 'Hitobito')
  end

  def base32_encode(str)
    b32 = ''
    str.each_byte do |b|
      b32 += ROTP::Base32::CHARS[b % 32]
    end
    b32
  end

  def base_secret
    Hitobito::Application.config.secret_key_base
  end

end
