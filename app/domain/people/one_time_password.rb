# frozen_string_literal: true

class People::OneTimePassword

  def self.generate_secret
    ROTP::Base32.random
  end

  def initialize(username)
    raise 'username cant be blank' if username.blank?

    @username = username
  end

  def provisioning_uri
    authenticator.provisioning_uri(username)
  end

  def provisioning_qr_code
    RQRCode::QRCode.new(provisioning_uri).as_png(module_px_size: 3)
  end

  def verify(token)
    return false if username.blank?

    authenticator.verify(token)
  end

  private

  attr_accessor :username

  def secret
    base = "#{base_secret}-#{username}"
    sha = Digest::SHA512.hexdigest(base)
    base32_encode(sha)
  end

  def authenticator
    # TODO: add issuer
    ROTP::TOTP.new(secret)
  end

  def base32_encode(str)
    b32 = ''
    str.each_byte do |b|
      b32 += ROTP::Base32::CHARS[b % 32]
    end
    b32
  end

  def base_secret
    Cryptopus::Application.config.secret_key_base
  end

end
