# frozen_string_literal: true

#  Copyright (c) 2020-2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::Pdf::Messages::Letter
  class Header < Section
    LOGO_BOX = [200, 40].freeze
    ADDRESS_BOX = [200, 60].freeze
    SHIPPING_INFO_BOX = [ADDRESS_BOX.first, 20].freeze

    delegate :group, to: 'letter'

    def render(recipient) # rubocop:disable Metrics/MethodLength
      stamped :render_header

      offset_cursor_from_top 52.5.mm

      stamped :render_shipping_info

      render_address(recipient.address)

      stamped :render_subject if letter.subject.present?
    end

    private

    def render_header
      if letter.heading?
        render_logo_right
        pdf.move_up 40

        render_address(sender_address)
      end
    end

    def render_subject
      offset_cursor_from_top 107.5.mm

      pdf.text(letter.subject, style: :bold)
      pdf.move_down pdf.font_size * 2
    end

    def render_logo_right(width: LOGO_BOX.first, height: LOGO_BOX.second)
      left = bounds.width - width
      bounding_box([left, cursor], width: width, height: height) do
        if logo_path
          image(logo_path, position: :right, fit: [width, height])
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

    def render_shipping_info(width: SHIPPING_INFO_BOX.first, height: SHIPPING_INFO_BOX.second)
      bounding_box([0, cursor], width: width, height: height) do
        shipping_method = { own: '',
                            normal: 'P.P.',
                            priority: 'P.P. A' }[letter.shipping_method.to_sym]
        pdf.move_up 2
        text('Post CH AG', align: :center, size: 7.pt)
        pdf.move_down 2
        text("<u><font size='12pt'><b>#{shipping_method} </b></font>" \
             "<font size='8pt'>#{letter.pp_post}</font></u>",
             inline_format: true)
      end
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
       [group.zip_code, group.town].compact.join(' ').squish].compact.join("\n")
    end

    def address_present?(group)
      [:address, :town].all? { |a| group.send(a)&.strip.present? }
    end
  end
end
