# encoding: utf-8

#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Invoice
  class PaymentSlipQr < Section
    include ActionView::Helpers::NumberHelper
    require 'prawn/measurement_extensions'

    delegate :start_new_page, :move_cursor_to, :horizontal_line, :vertical_line,
      :stroke, :bounds, :font, :text_box, :move_down, to: :pdf

    delegate :creditor_values, :debitor_values, to: 'invoice.qrcode'

    HEIGHT = 105.mm
    WIDTH_PAYMENT = 148.mm
    WIDTH_RECEIPT = 62.mm
    WIDTH = WIDTH_RECEIPT + WIDTH_PAYMENT
    MARGIN = Export::Pdf::Invoice::MARGIN

    HEIGHT_WITHOUT_MARGIN = HEIGHT - MARGIN

    def render # rubocop:disable Metrics/MethodLength
      start_new_page if cursor < HEIGHT + MARGIN

      stamped :separators

      receipt do
        receipt_titel
        receipt_infos
        receipt_amount
        receipt_receiving_office
      end

      payment do
        stamped :payment_titel
        payment_qrcode
        stamped :payment_amount
        payment_infos
        payment_extra_infos
      end
    end

    def separators
      stroke do
        horizontal_line MARGIN * -1, WIDTH + MARGIN, at: HEIGHT_WITHOUT_MARGIN
        scissor_image :horizontal, at: [WIDTH - 1.5 * MARGIN, HEIGHT_WITHOUT_MARGIN + 2.mm]

        vertical_line MARGIN * -1, HEIGHT_WITHOUT_MARGIN, at: WIDTH_RECEIPT - MARGIN
        scissor_image :vertical, at: [WIDTH_RECEIPT - MARGIN * 1.1, MARGIN * -0.5]
      end
    end

    def scissor_image(kind, at:)
      image invoice.qrcode.scissor(kind), at: at, scale: 0.1
    end

    def receipt
      bounding_box([-MARGIN, HEIGHT_WITHOUT_MARGIN], width: WIDTH_RECEIPT, height: HEIGHT) { yield }
      @padded_percent = 0
    end

    def payment
      width = bounds.width - WIDTH_RECEIPT + 4.cm
      box = [WIDTH_RECEIPT - MARGIN, HEIGHT_WITHOUT_MARGIN]
      bounding_box(box, width: width, height: HEIGHT) { yield }
    end

    def payment_titel
      padded_bounding_box(0.1, width: 60.mm, pad_right: false) do
        font 'Helvetica', size: 11, style: :bold do
          text 'Zahlteil'
        end
      end
    end

    def payment_qrcode
      padded_bounding_box(0.6, width: 60.mm, pad_right: true) do
        invoice.qrcode.generate do |path|
          image path, fit: [46.mm, 46.mm], position: :center, vposition: :center
        end
      end
    end

    def payment_amount
      padded_bounding_box(0.15, width: 60.mm, pad_right: false) { amount_box }
    end

    def payment_infos
      padded_bounding_box(0.15, pad_right: true)
    end

    def payment_extra_infos
      @padded_percent = 0
      width = bounds.width - 60.mm
      padded_bounding_box(0.85, x: 60.mm, width: width, pad_right: false) do
        info_box
      end
    end

    def receipt_titel
      padded_bounding_box(0.1, pad_right: true) do
        heading(size: 11) { text 'Empfangsschein' }
      end
    end

    def receipt_infos
      padded_bounding_box(0.6, pad_right: true) { info_box }
    end

    def receipt_amount
      padded_bounding_box(0.15, pad_right: true) { amount_box }
    end

    def receipt_receiving_office
      padded_bounding_box(0.15, pad_right: true) do
        heading do
          move_down 10
          pdf.text 'Annahmestelle', align: :right
        end
      end
    end

    def info_box # rubocop:disable Metrics/MethodLength
      heading do
        text_box 'Konto / Zahlbar an', at: [0, cursor]
      end
      content do
        text_box creditor_values, at: [0, cursor]
      end

      move_down 24.mm

      heading do
        text_box 'Zahlbar durch', at: [0, cursor]
      end
      content do
        text_box debitor_values, at: [0, cursor]
      end
    end

    def amount_box
      heading do
        text_box 'Währung', at: [0, cursor]
        text_box 'Betrag', at: [20.mm, cursor]
      end
      content do
        text_box invoice.currency, at: [0, cursor]
        if invoice.total.zero?
          blank_amount_rectangle
        else
          amount = number_with_precision(invoice.total, precision: 2, delimiter: ' ')
          text_box amount, at: [20.mm, cursor]
        end
      end
    end

    # rubocop:disable Metrics/AbcSize
    def blank_amount_rectangle(width: 90, height: 30, length: 10)
      pdf.translate 20.mm, cursor do
        pdf.stroke do
          pdf.line_width = 0.5
          # top left
          pdf.line [0, 0], [length, 0] # right
          pdf.line [0, 0], [0, -length] # down
          # top right
          pdf.line [width, 0], [width - length, 0] # left
          pdf.line [width, 0], [width, -length] # down
          # bottom left
          pdf.line [0, -height], [length, -height] # right
          pdf.line [0, -height], [0, -(height -length)] # up
          # bottom right
          pdf.line [width, -height], [width - length, -height] # left
          pdf.line [width, -height], [width, -(height - length)] # down
        end
      end
    end

    def content
      font 'Helvetica', size: 10 do
        yield
      end
    end

    def heading(size: 8)
      font 'Helvetica', size: size, style: :bold do
        yield
      end
      move_down size + 2
    end

    PAD = 5.mm

    def padded_height
      HEIGHT - 2 * PAD
    end

    # https://stackoverflow.com/questions/4600153/how-do-i-set-margins-in-prawn-in-ruby
    def padded_bounding_box(percent, width: bounds.width, pad_right: false, x: PAD)
      @padded_percent ||= 0
      raise 'exceeding size' if @padded_percent + percent > 1

      computed_height = padded_height * percent
      computed_width  = width - (pad_right ? (PAD * 2) : PAD)
      y = HEIGHT - PAD - (@padded_percent * padded_height)

      bounding_box([x, y], width: computed_width, height: computed_height) do
        yield if block_given?
      end
      @padded_percent += percent
    end

  end
end
