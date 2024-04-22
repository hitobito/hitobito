# frozen_string_literal: true

#  copyright (c) 2024, schweizer alpen-club. this file is part of
#  hitobito and licensed under the affero general public license version 3
#  or later. see the copying file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class People::Membership::VerificationQrCode

  def initialize(person)
    assert_feature_enabled!

    @person = person
  end

  def generate
    RQRCode::QRCode.new(verify_url)
  end

  private

  def membership_verify_token
    @person.membership_verify_token
  end

  def verify_url
    host = ENV.fetch('RAILS_HOST_NAME', 'localhost:3000')
    Rails
      .application
      .routes
      .url_helpers
      .verify_membership_url(host: host, verify_token: membership_verify_token)
  end

  def assert_feature_enabled!
    unless People::Membership::Verifier.enabled?
      raise 'membership verification feature not enabled'
    end
  end

end
