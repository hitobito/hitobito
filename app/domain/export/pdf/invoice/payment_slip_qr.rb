#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Invoice
  class PaymentSlipQr < Section # rubocop:todo Metrics/ClassLength
    include ActionView::Helpers::NumberHelper
    require "prawn/measurement_extensions"

    delegate :start_new_page, :move_cursor_to, :horizontal_line, :vertical_line,
      :stroke, :bounds, :font, :text_box, :move_down, to: :pdf

    delegate :formatted_creditor, :formatted_debitor, to: "invoice.qrcode"

    HEIGHT = 105.mm
    WIDTH_PAYMENT = 148.mm
    WIDTH_RECEIPT = 62.mm
    WIDTH = WIDTH_RECEIPT + WIDTH_PAYMENT
    MARGIN = Export::Pdf::Invoice::MARGIN
    FONT_FAMILY = "LiberationSans"

    HEIGHT_WITHOUT_MARGIN = HEIGHT - MARGIN

    def render # rubocop:disable Metrics/MethodLength
      start_new_page if cursor < HEIGHT_WITHOUT_MARGIN

      stamped :separators

      font FONT_FAMILY do
        font_size(8) do
          receipt do
            receipt_title
            receipt_infos
            receipt_amount
            receipt_receiving_office
          end
        end

        font_size(10) do
          payment do
            stamped :payment_title
            payment_qrcode
            render_payment_amount
            payment_infos
            payment_extra_infos
          end
        end
      end
    end

    def height
      HEIGHT - MARGIN
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

    def payment_title
      padded_bounding_box(0.1, width: 60.mm, pad_right: false) do
        font_size(11) do
          bold { text t("payment_title") }
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

    def render_payment_amount
      if invoice.includes_dynamic_invoice_items?
        payment_amount
      else
        stamped :payment_amount
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
      # render_esr_number is only true if invoice.esr_number is present
      # condition currently only applies in SAC wagon
      padded_bounding_box(0.85, x: 60.mm, width: width, pad_right: false) do
        info_box
      end
    end

    def receipt_title
      padded_bounding_box(0.1, pad_right: true) do
        font_size(11) do
          bold { text t("receipt_title") }
        end
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
        bold do
          move_down 10
          pdf.text t("receiving_office"), align: :right
        end
      end
    end

    def info_box
      creditor_box
      move_down 10

      esr_number_box if invoice.esr_number.present?
      move_down 10 if invoice.esr_number.present?

      debitor_box
      move_down 10
    end

    def creditor_box
      bounding_box([0, cursor], width: bounds.width) do
        bold do
          text t("creditor_heading")
        end
        text formatted_creditor
      end
    end

    def esr_number_box
      bounding_box([0, cursor], width: bounds.width) do
        bold do
          text t("esr_number_heading")
        end
        text invoice.esr_number
      end
    end

    def debitor_box
      bounding_box([0, cursor], width: bounds.width) do
        bold do
          text t("debitor_heading")
        end
        text formatted_debitor
      end
    end

    def amount_box # rubocop:todo Metrics/AbcSize
      bounding_box([0, cursor], width: bounds.width) do
        bold do
          text_box t("currency"), at: [0, cursor]
          text_box t("amount"), at: [20.mm, cursor]
        end

        move_down 12

        text_box invoice.currency, at: [0, cursor]

        if invoice.total.zero? || invoice.hide_total?
          move_down 12
          blank_amount_rectangle
        else
          amount = number_with_precision(invoice.amount_open, precision: 2, delimiter: " ")
          text_box amount, at: [20.mm, cursor]
        end
      end
    end

    # rubocop:todo Lint/MissingCopEnableDirective
    # rubocop:disable Metrics/AbcSize # rubocop:todo Lint/MissingCopEnableDirective
    # rubocop:enable Lint/MissingCopEnableDirective
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
          pdf.line [0, -height], [0, -(height - length)] # up
          # bottom right
          pdf.line [width, -height], [width - length, -height] # left
          pdf.line [width, -height], [width, -(height - length)] # down
        end
      end
    end

    def bold
      font FONT_FAMILY, style: :bold do
        yield
      end
    end

    PAD = 5.mm

    def padded_height
      HEIGHT - 2 * PAD
    end

    # https://stackoverflow.com/questions/4600153/how-do-i-set-margins-in-prawn-in-ruby
    def padded_bounding_box(percent, width: bounds.width, pad_right: false, x: PAD)
      @padded_percent ||= 0
      raise "exceeding size" if @padded_percent + percent > 1

      computed_height = padded_height * percent
      computed_width = width - (pad_right ? (PAD * 2) : PAD)
      y = HEIGHT - PAD - (@padded_percent * padded_height)

      bounding_box([x, y], width: computed_width, height: computed_height) do
        yield if block_given?
      end
      @padded_percent += percent
    end

    private

    def t(key)
      I18n.t("invoices.pdf.payment_slip_qr.#{key}")
    end
  end
end
