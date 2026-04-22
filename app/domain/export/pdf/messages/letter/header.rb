# frozen_string_literal: true

#  Copyright (c) 2020-2024, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::Pdf::Messages::Letter
  class Header < Section
    include Export::Pdf::AddressRenderers
    include Export::Pdf::ShippingInfoRenderers

    LOGO_BOX = [450, 40].freeze
    ADDRESS_BOX = [address_box_width, address_box_height].freeze

    delegate :group, to: "letter"

    def render(recipient, font_size: 9) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
      stamped :render_logo_right

      offset_cursor_from_top 60.mm
      bounding_box(address_position(group.letter_address_position), width: address_box_width) do
        stamped :render_shipping_info_block
        pdf.move_down 4.mm # 3mm + 1mm from text baseline, according to post factsheet
        render_address(recipient)
      end

      pdf.font_size font_size do
        stamped :render_date_location_text if letter.date_location_text.present?
        stamped :render_subject if letter.subject.present?
      end
    end

    private

    def render_shipping_info_block
      render_shipping_info(letter, width: address_box_width)
    end

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

    def render_address(recipient, width: address_box_width, height: address_box_height)
      bounding_box([0, cursor], width: width, height: height) do
        text recipient.address
      end
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
        ""
      end
    end

    def group_address(group)
      [group.name.to_s.squish,
        group.address.to_s.squish,
        [group.zip_code, group.town].compact.join(" ").squish].compact.join("\n")
    end

    def address_present?(group)
      [:address, :town].all? { |a| group.send(a)&.strip.present? }
    end
  end
end
