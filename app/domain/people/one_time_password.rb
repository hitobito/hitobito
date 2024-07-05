# frozen_string_literal: true

# Copyright (c) 2021, hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https ://github.com/hitobito/hitobito.

class People::OneTimePassword
  def self.generate_secret
    ROTP::Base32.random
  end

  def initialize(totp_secret, person: nil)
    raise "totp_secret cant be blank" if totp_secret.blank?

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
    drift = Settings.people.totp_drift
    authenticator.verify(token, drift_ahead: drift, drift_behind: drift)
  end

  def secret
    base = "#{base_secret}-#{totp_secret}"
    sha = Digest::SHA512.hexdigest(base)
    base32_encode(sha)
  end

  private

  attr_accessor :totp_secret, :person

  def authenticator
    ROTP::TOTP.new(secret, issuer: issuer)
  end

  def issuer
    issuer = Settings.application.name.to_s
    issuer += " - #{Rails.env}" unless Rails.env.production?
    issuer
  end

  def base32_encode(str)
    ROTP::Base32.encode(str)
  end

  def base_secret
    Hitobito::Application.config.secret_key_base
  end
end
