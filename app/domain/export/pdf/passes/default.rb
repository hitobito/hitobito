#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export
  module Pdf
    module Passes
      class Default
        # Credit card ISO/IEC 7810 ID-1: 85.6mm × 53.98mm
        CARD_WIDTH = 85.6.mm
        CARD_HEIGHT = 53.98.mm
        CARD_RADIUS = 3.mm
        CARD_GAP = 0.mm # front and back touch for fold-in-half
        CROP_MARK_LENGTH = 5.mm
        CROP_MARK_OFFSET = 2.mm

        # Address window position for DIN C5/6 envelope (left window)
        ADDRESS_TOP = 50.mm  # from page top
        ADDRESS_LEFT = 20.mm # from page left

        FONT = "NotoSans"

        attr_reader :person, :pass_definition, :pass, :pdf

        def initialize(person, pass_definition)
          @person = person
          @pass_definition = pass_definition
          @pass = Pass.new(person: person, definition: pass_definition)
        end

        def render
          doc = Export::Pdf::Document.new(page_size: "A4", page_layout: :portrait, margin: 0)
          @pdf = doc.pdf
          pdf.font FONT

          render_address
          render_cards_with_crop_marks

          pdf.render
        end

        def filename
          parts = ["pass", pass_definition.name.parameterize(separator: "_")]
          parts << person.full_name.parameterize(separator: "_")
          [parts.join("-"), :pdf].join(".")
        end

        private

        # --- Address block (envelope-compatible) ---

        def render_address
          pdf.bounding_box(
            [ADDRESS_LEFT, pdf.bounds.top - ADDRESS_TOP],
            width: 80.mm, height: 40.mm
          ) do
            sender = sender_address
            if sender.present?
              pdf.text sender, size: 6, style: :italic, color: "666666"
              pdf.stroke do
                pdf.horizontal_line 0, 80.mm
              end
              pdf.move_down 2.mm
            end
            pdf.text person_address, size: 10, leading: 2
          end
        end

        def person_address
          Contactable::Address.new(person).for_letter
        end

        # Build one-line sender address from the pass definition's owner group
        # (or its layer group). Mirrors Letter::Header#sender_address.
        def sender_address
          group = pass_definition.owner
          if group_address_present?(group)
            group_address_line(group)
          elsif group_address_present?(group.layer_group)
            group_address_line(group.layer_group)
          end
        end

        def group_address_line(group)
          [group.name.to_s.squish,
            group.address.to_s.squish,
            [group.zip_code, group.town].compact.join(" ").squish]
            .select(&:present?).join(", ")
        end

        def group_address_present?(group)
          return false unless group

          [:address, :town].all? { |a| group.send(a)&.strip.present? }
        end

        # --- Side-by-side cards with crop marks ---

        def render_cards_with_crop_marks
          total_width = (CARD_WIDTH * 2) + CARD_GAP
          front_x = (pdf.bounds.width - total_width) / 2
          back_x = front_x + CARD_WIDTH + CARD_GAP
          card_y = pdf.bounds.top - 110.mm

          draw_crop_marks_for_pair(front_x, back_x, card_y)
          draw_front_card(front_x, card_y)
          draw_back_card(back_x, card_y)
        end

        def draw_crop_marks_for_pair(front_x, back_x, card_y)
          pdf.line_width = 0.25

          # Outer corners of the pair (front-left + back-right)
          outer_corners = [
            [front_x, card_y],                            # top-left
            [back_x + CARD_WIDTH, card_y],                 # top-right
            [front_x, card_y - CARD_HEIGHT],               # bottom-left
            [back_x + CARD_WIDTH, card_y - CARD_HEIGHT]    # bottom-right
          ]

          outer_corners.each_with_index do |(cx, cy), i|
            h_dir = (i % 2 == 0) ? -1 : 1
            v_dir = (i < 2) ? 1 : -1

            pdf.stroke_line(
              [cx + h_dir * CROP_MARK_OFFSET, cy],
              [cx + h_dir * (CROP_MARK_OFFSET + CROP_MARK_LENGTH), cy]
            )
            pdf.stroke_line(
              [cx, cy + v_dir * CROP_MARK_OFFSET],
              [cx, cy + v_dir * (CROP_MARK_OFFSET + CROP_MARK_LENGTH)]
            )
          end

          # Fold line between front and back (top + bottom marks)
          fold_x = front_x + CARD_WIDTH
          pdf.stroke_line([fold_x, card_y + CROP_MARK_OFFSET],
            [fold_x, card_y + CROP_MARK_OFFSET + CROP_MARK_LENGTH])
          pdf.stroke_line([fold_x, card_y - CARD_HEIGHT - CROP_MARK_OFFSET],
            [fold_x, card_y - CARD_HEIGHT - CROP_MARK_OFFSET - CROP_MARK_LENGTH])
        end

        # === Front card ===

        def draw_front_card(card_x, card_y)
          bg_color = normalized_bg_color
          colors = card_colors(bg_color)

          pdf.fill_color bg_color
          pdf.fill_rounded_rectangle([card_x, card_y], CARD_WIDTH, CARD_HEIGHT, CARD_RADIUS)
          pdf.fill_color "000000"

          padding = 4.mm
          inner_width = CARD_WIDTH - (2 * padding)
          content_x = card_x + padding
          content_top = card_y - padding

          render_front_header(content_x, content_top, inner_width, colors)

          body_top = content_top - 12.mm
          render_front_body(content_x, body_top, inner_width, colors)

          footer_top = card_y - CARD_HEIGHT + padding + 10.mm
          render_front_footer(content_x, footer_top, inner_width, colors)
        end

        def render_front_header(x, y, width, colors)
          logo_w = render_header_logo(x, y, width)

          title_width = width - logo_w - (logo_w > 0 ? 2.mm : 0)
          with_color(colors[:text]) do
            pdf.text_box pass_definition.name,
              at: [x, y],
              width: title_width,
              height: 9.mm,
              size: 9,
              style: :bold,
              overflow: :shrink_to_fit
          end
        end

        def render_header_logo(x, y, width)
          logo_group_record = logo_group
          if logo_group_record
            render_group_logo(logo_group_record, x, y, width)
          else
            render_settings_logo(x, y, width)
          end
        end

        def render_group_logo(logo_group_record, x, y, width)
          logo_w = 20.mm
          logo_group_record.logo.blob.open do |logo_file|
            pdf.image(logo_file,
              at: [x + width - logo_w, y],
              fit: [logo_w, 9.mm])
          end
          logo_w
        rescue
          0
        end

        def render_settings_logo(x, y, width)
          logo_path = settings_logo_file_path
          return 0 unless logo_path

          logo_w = 20.mm
          pdf.image(logo_path,
            at: [x + width - logo_w, y],
            fit: [logo_w, 9.mm])
          logo_w
        rescue
          0
        end

        # Resolve Settings.application.logo to an absolute file path on disk.
        # Checks wagon image directories first (mirroring WebpackHelper), then core.
        def settings_logo_file_path
          logo_image = Settings.application.logo&.image
          return nil if logo_image.blank?

          Wagons.all.each do |wagon|
            path = File.join(wagon.root, "app", "javascript", "images", logo_image)
            return path if File.exist?(path)
          end

          core_path = Rails.root.join("app", "javascript", "images", logo_image)
          return core_path.to_s if core_path.exist?

          nil
        end

        def render_front_body(x, y, width, colors)
          cursor_y = y

          # Person photo (left) + info (right)
          photo_width = 0
          if person.picture.attached?
            photo_width = 12.mm
            photo_height = 16.mm
            begin
              person.picture.blob.open do |photo_file|
                pdf.image(photo_file,
                  at: [x, cursor_y],
                  fit: [photo_width, photo_height])
              end
            rescue
              photo_width = 0
            end
          end

          info_x = x + (photo_width > 0 ? photo_width + 2.mm : 0)
          info_width = width - (photo_width > 0 ? photo_width + 2.mm : 0)
          info_y = cursor_y

          # Member name
          with_color(colors[:text]) do
            pdf.text_box pass.member_name,
              at: [info_x, info_y],
              width: info_width,
              height: 5.mm,
              size: 10,
              style: :bold,
              overflow: :shrink_to_fit
          end
          info_y -= 6.mm

          # Member number label
          with_color(colors[:label]) do
            pdf.text_box I18n.t("wallets.pass.member_number").upcase,
              at: [info_x, info_y],
              width: info_width,
              height: 3.mm,
              size: 5,
              style: :bold
          end
          info_y -= 3.mm

          # Member number value
          with_color(colors[:text]) do
            pdf.text_box pass.member_number.to_s,
              at: [info_x, info_y],
              width: info_width,
              height: 4.mm,
              size: 8,
              overflow: :shrink_to_fit
          end
        end

        def render_front_footer(x, y, width, colors)
          validity_lines = []
          if pass.valid_from.present?
            validity_lines << "#{I18n.t("wallets.pass.valid_from")} #{I18n.l(pass.valid_from)}"
          end
          if pass.valid_until.present?
            validity_lines << "#{I18n.t("wallets.pass.valid_until")} #{I18n.l(pass.valid_until)}"
          end

          if validity_lines.any?
            with_color(colors[:muted]) do
              pdf.text_box validity_lines.join("\n"),
                at: [x, y],
                width: width,
                height: 8.mm,
                size: 6,
                overflow: :shrink_to_fit
            end
          end
        end

        # === Back card ===

        def draw_back_card(card_x, card_y)
          bg_color = normalized_bg_color
          colors = card_colors(bg_color)

          pdf.fill_color bg_color
          pdf.fill_rounded_rectangle([card_x, card_y], CARD_WIDTH, CARD_HEIGHT, CARD_RADIUS)
          pdf.fill_color "000000"

          padding = 4.mm
          inner_width = CARD_WIDTH - (2 * padding)
          content_x = card_x + padding
          center_x = card_x + (CARD_WIDTH / 2)

          # QR code placeholder (centered, large)
          qr_size = 25.mm
          qr_x = center_x - (qr_size / 2)
          qr_y = card_y - 6.mm

          # White background behind QR for readability
          pdf.fill_color "FFFFFF"
          pdf.fill_rounded_rectangle([qr_x, qr_y], qr_size, qr_size, 2.mm)
          pdf.fill_color "000000"

          pdf.stroke_color colors[:muted]
          pdf.stroke_rounded_rectangle([qr_x, qr_y], qr_size, qr_size, 2.mm)
          pdf.stroke_color "000000"

          with_color(colors[:label]) do
            pdf.text_box "QR",
              at: [qr_x, qr_y - (qr_size / 2) + 2.mm],
              width: qr_size,
              height: 4.mm,
              size: 8,
              align: :center
          end

          # Description below QR
          desc_y = qr_y - qr_size - 3.mm
          if pass_definition.description.present?
            with_color(colors[:muted]) do
              pdf.text_box pass_definition.description,
                at: [content_x, desc_y],
                width: inner_width,
                height: 8.mm,
                size: 6,
                align: :center,
                overflow: :shrink_to_fit
            end
            desc_y -= 8.mm
          end

          # Pass title repeated small
          with_color(colors[:label]) do
            pdf.text_box pass_definition.name.upcase,
              at: [content_x, card_y - CARD_HEIGHT + padding + 5.mm],
              width: inner_width,
              height: 4.mm,
              size: 5,
              align: :center,
              style: :bold,
              overflow: :shrink_to_fit
          end
        end

        # --- Helpers ---

        def card_colors(bg_color)
          light = light_background?(bg_color)
          {
            text: light ? "333333" : "FFFFFF",
            muted: light ? "666666" : "CCCCCC",
            label: light ? "888888" : "AAAAAA"
          }
        end

        def with_color(color)
          pdf.fill_color color
          yield
          pdf.fill_color "000000"
        end

        def normalized_bg_color
          color = pass_definition.background_color.to_s
          color.delete_prefix("#").presence || "FFFFFF"
        end

        def light_background?(hex_color)
          r = hex_color[0..1].to_i(16)
          g = hex_color[2..3].to_i(16)
          b = hex_color[4..5].to_i(16)
          luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
          luminance > 0.5
        end

        def logo_group
          group = pass_definition.owner
          group.self_and_ancestors.includes(logo_attachment: :blob).reverse.find do |g|
            g.logo.attached?
          end
        end
      end
    end
  end
end
