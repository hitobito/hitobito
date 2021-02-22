# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::Pdf::Messages::Letter
  class Header < Section
    LOGO_BOX = [200, 40]
    ADDRESS_BOX = [200, 40]

    def render(recipient)
      render_logo
      pdf.move_down 10

      render_address(sender_address)
      pdf.move_down 20
      render_address(build_address(recipient))

      pdf.move_down 50
    end

    private

    def render_logo(width: LOGO_BOX.first, height: LOGO_BOX.second)
      bounding_box([0, cursor], width: width, height: height) do
        image logo_path, fit: [width, height]
      end
    end

    def render_address(address, width: ADDRESS_BOX.first, height: ADDRESS_BOX.second)
      bounding_box([0, cursor], width: width, height: height) do
        text sanitize(address)
      end
    end

    def build_address(recipient)
      [recipient.full_name.to_s.squish,
       recipient.address.to_s.squish,
       [recipient.zip_code, recipient.town].compact.join(" ").squish,
       recipient.country.to_s.squish,].compact.join("\n")
    end

    def logo_path
      Settings.messages.pdf.logo.to_s
    end

    def sender_address
      Settings.messages.pdf.address
    end
  end
end
