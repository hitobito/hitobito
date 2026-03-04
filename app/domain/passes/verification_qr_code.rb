#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Passes
  class VerificationQrCode
    attr_reader :person, :definition

    def initialize(person, definition)
      @person = person
      @definition = definition
    end

    def verify_url
      Rails.application.routes.url_helpers.pass_verify_url(
        definition.id,
        person.membership_verify_token,
        host: host
      )
    end

    def generate
      RQRCode::QRCode.new(verify_url)
    end

    private

    def host
      ENV.fetch("RAILS_HOST_NAME", "localhost:3000")
    end
  end
end
