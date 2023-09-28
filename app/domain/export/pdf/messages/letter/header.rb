# frozen_string_literal: true

#  Copyright (c) 2020-2022, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::Pdf::Messages::Letter
  class Header < Section
    include Export::Pdf::AddressRenderers

    LOGO_BOX = [450, 40].freeze
    ADDRESS_BOX = [58.mm, 60].freeze
    SHIPPING_INFO_BOX = [ADDRESS_BOX.first, 24].freeze

    delegate :group, to: 'letter'

    def render(recipient, font_size: 9)
      stamped :render_logo_right

      offset_cursor_from_top 60.mm
      bounding_box(address_position(group), width: ADDRESS_BOX.first) do
        stamped :render_shipping_info

        pdf.move_down 4.mm # 3mm + 1mm from text baseline, according to post factsheet
        render_address(recipient)


      end
      pdf.font_size font_size do
        stamped :render_date_location_text if letter.date_location_text.present?
        stamped :render_subject if letter.subject.present?
      end
    end

    private

    def render_date_location_text
      offset_cursor_from_top 97.5.mm
      pdf.text(letter.date_location_text)
    end

    def render_subject
      offset_cursor_from_top 107.5.mm
      pdf.text(letter.subject, style: :bold)
      pdf.move_down pdf.font_size * 2
    end

    def render_logo_right(width: LOGO_BOX.first, height: LOGO_BOX.second)
      Export::Pdf::Logo.new(
        pdf,
        logo_attachment,
        image_width: [width, bounds.width].min,
        image_height: height,
        position: :right
      ).render
    end

    def render_address(recipient, width: ADDRESS_BOX.first, height: ADDRESS_BOX.second)
      bounding_box([0, cursor], width: width, height: height) do
        text recipient.address
      end
    end

    def render_shipping_info(width: SHIPPING_INFO_BOX.first, height: SHIPPING_INFO_BOX.second)
      render_shipping_info_post_logo(width) unless letter.own?
      render_shipping_info_text(width, height)
      render_shipping_info_line unless shipping_info_empty?
    end

    def render_shipping_info_post_logo(width)
      text_box('Post CH AG', align: :center, size: 7.pt, width: width, at: [0, cursor + 18.pt])
    end

    def render_shipping_info_text(width, height)
      shipping_method, text_height = shipping_methods[letter.shipping_method.to_sym]
      text_box("#{shipping_method}<font size='8pt'>#{letter.pp_post}</font>",
               inline_format: true, overflow: :truncate, single_line: true,
               width: width, height: height, at: [0, cursor + text_height * 0.75])
    end

    def render_shipping_info_line
      pdf.stroke do
        pdf.move_down 1.mm
        # post factsheet: max. 11 cm, start and end of the line MUST be visible in the window
        pdf.horizontal_line 0, ADDRESS_BOX.first
        pdf.move_up 1.mm
      end
    end

    def shipping_info_empty?
      letter.own? && letter.pp_post.to_s.strip.blank?
    end

    def logo_attachment
      logo_path_setting(group) || logo_path_setting(group.layer_group)
    end

    def logo_path_setting(group)
      group.letter_logo if group.letter_logo.attached?
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
      { own: ['', 8.pt],
        normal: ["<b><font size='12pt'>P.P.</font></b> ", 12.pt],
        priority: ["<b><font size='12pt'>P.P.</font> <font size='24pt'>A</font></b> ", 24.pt] }
    end
  end
end
