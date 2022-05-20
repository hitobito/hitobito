# frozen_string_literal: true

#  Copyright (c) 2020-2022, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::Pdf::Messages::Letter
  class Header < Section
    LOGO_BOX = [450, 40].freeze
    ADDRESS_BOX = [200, 60].freeze
    SHIPPING_INFO_BOX = [ADDRESS_BOX.first, 24].freeze

    delegate :group, to: 'letter'

    def render(recipient)
      stamped :render_logo_right

      offset_cursor_from_top 52.5.mm

      stamped :render_shipping_info

      pdf.move_down 3.mm # According to post factsheet

      render_address(recipient.address)

      stamped :render_date_location_text if letter.date_location_text.present?
      stamped :render_subject if letter.subject.present?
    end

    private

    def render_date_location_text
      offset_cursor_from_top 102.5.mm
      pdf.text(letter.date_location_text)
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
          image(StringIO.open(logo_path.download),
                logo_options(width, height))
        else
          ''
        end
      end
    end

    def logo_options(box_width, box_height)
      opts = { position: :right }
      if logo_exceeds_box?(box_width, box_height)
        opts[:fit] = [box_width, box_height]
      end
      opts
    end

    def logo_exceeds_box?(box_width, box_height)
      width, height = logo_dimensions
      width > box_width || height > box_height
    end

    def logo_dimensions
      logo_path.analyze unless logo_path.analyzed?
      metadata = logo_path.blob.metadata

      [metadata[:width], metadata[:height]]
    end

    def render_address(address, width: ADDRESS_BOX.first, height: ADDRESS_BOX.second)
      bounding_box([0, cursor], width: width, height: height) do
        text sanitize(address)
      end
    end

    def render_shipping_info(width: SHIPPING_INFO_BOX.first, height: SHIPPING_INFO_BOX.second)
      bounding_box([0, cursor], width: width, height: height) do
        shipping_method = shipping_methods[letter.shipping_method.to_sym]
        pdf.move_up 2
        text('Post CH AG', align: :center, size: 7.pt) unless letter.own?
        pdf.move_down 2
        text_box("<u>#{shipping_method}<font size='8pt'>#{letter.pp_post}</font></u>",
                 inline_format: true, overflow: :truncate, single_line: true,
                 width: width, height: height, at: [0, cursor])
      end
    end

    def logo_path
      logo_path_setting(group) || logo_path_setting(group.layer_group)
    end

    def logo_path_setting(group)
      setting = group.settings(:messages_letter)

      setting.picture if setting.picture.attached?
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

    def shipping_methods
      { own: '',
        normal: "<b><font size='12pt'>P.P.</font></b> ",
        priority: "<b><font size='12pt'>P.P.</font> <font size='24pt'>A</font></b> " }
    end
  end
end
