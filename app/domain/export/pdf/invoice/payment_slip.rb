# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Invoice
  class PaymentSlip < Section

    def render
      pdf.start_new_page if cursor < 225
      stamped(:invoice_address) { invoice_address }
      stamped(:account_number) { account_number }
      stamped(:amount) { amount } if invoice_items.present?
      invoice.with_reference? ? esr_number : payment_purpose
      left_receiver_address
      right_receiver_address
      code_line if invoice.with_reference?
    end

    private

    def invoice_address
      if invoice.bank?
        bank_invoice_address
      else
        post_invoice_address
      end
    end

    def bank_invoice_address
      [-50, 125].each do |x|
        bounding_box([x, 220], width: 150, height: 80) do
          text invoice.payee
        end
        bounding_box([x, 180], width: 150, height: 80) do
          pdf.font('Courier', size: 9) { text invoice.iban }
          pdf.move_down(3)
          text invoice.beneficiary
        end
      end
    end

    def post_invoice_address
      [-50, 125].each do |x|
        bounding_box([x, 210], width: 150, height: 80) do
          text invoice.address
        end
      end
    end

    def account_number
      number = with_reference? ? participant_number : invoice.account_number

      [15, 195].each do |x|
        bounding_box([x, 122], width: 85, height: 10) do
          pdf.font('ocrb', size: 10) { text number }
        end
      end
    end

    def amount
      [-58, 120].each do |x|
        pdf.font('Courier', size: 12) do
          bounding_box([x, 100], width: 145) do
            table amount_data(0), cell_style: { padding: [2, 3.7, 1, 3.7], borders: [] }
          end

          bounding_box([x + 131, 100], width: 36) do
            table amount_data(1), cell_style: { padding: [2, 3.7, 1, 3.7], borders: [] }
          end
        end
      end
    end

    def esr_number
      bounding_box([295, 147], width: 235, height: 10) do
        pdf.font('ocrb', size: 10) do
          text invoice.esr_number
        end
      end
    end

    def payment_purpose
      bounding_box([295, 215], width: 150, height: 55) do
        text invoice.payment_purpose
      end
    end

    def left_receiver_address
      receiver_address(-50, 66) do
        if with_reference?
          pdf.text_box(invoice.esr_number,
                       at: [0, cursor], width: 150, height: 10,
                       overflow: :shrink_to_fit)
          pdf.move_down 7
        end
      end
    end

    def right_receiver_address
      receiver_address(295, 103)
    end

    def receiver_address(width, height)
      bounding_box([width, height], width: 150, height: 100) do
        yield if block_given?
        table receiver_address_data.take(3), cell_style: { padding: [3.5, 0, 1, 0], borders: [] }
      end
    end

    def code_line
      bounding_box([130, -4], width: 395, height: 10.2) do
        pdf.font('ocrb', size: 10.2) do
          text Invoice::PaymentSlip.new(invoice).code_line, align: :right
        end
      end
    end

    def amount_data(i)
      numbers = helper.number_to_currency(invoice.calculated[:total],
                                          format: '%n',
                                          delimiter: '').split('.')
      number_array = numbers[i].split('')
      return [number_array] if i != 0

      (8 - numbers[0].length).times { number_array = [' '] + number_array }
      [number_array]
    end
  end
end
