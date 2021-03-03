# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::Pdf::Messages::Letter
  class Header < Section
    LOGO_BOX = [200, 40].freeze
    ADDRESS_BOX = [200, 40].freeze

    delegate :group, to: '@letter'

    def render(recipient)
      if @letter.heading?
        render_logo
        pdf.move_down 10

        render_address(sender_address)
        pdf.move_down 20
      else
        pdf.move_down 110
      end

      render_address(build_address(recipient))
      pdf.move_down 50
    end

    private

    def render_logo(width: LOGO_BOX.first, height: LOGO_BOX.second)
      bounding_box([0, cursor], width: width, height: height) do
        if logo_path
          image logo_path, fit: [width, height]
        else
          ''
        end
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
       [recipient.zip_code, recipient.town].compact.join(' ').squish,
       recipient.country.to_s.squish].compact.join("\n")
    end

    def logo_path
      logo_path_setting(group) || logo_path_setting(group.layer_group)
    end

    def logo_path_setting(group)
      group.settings(:messages_letter).picture.path
    end

    def sender_address
      if address_present?(group)
        group_address(group)
      elsif address_present?(group.layer_group)
        group_address(group.layer_group)
      else
        ''
      end
    end

    def group_address(group)
      [group.name.to_s.squish,
       group.address.to_s.squish,
       [group.zip_code, group.town].compact.join(' ').squish,
       group.country.to_s.squish].compact.join("\n")
    end

    def address_present?(group)
      [:address, :town].all? { |a| group.send(a)&.strip.present? }
    end

  end

end
