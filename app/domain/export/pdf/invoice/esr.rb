# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Invoice
  class Esr < Section

    def render
      #image "#{Prawn::DATADIR}/images/esr.png", at: [-60, 248], width: 602
      invoice_address
      account_number
      price
      esr_number
      receiver_address
    end

    private

    def invoice_address
      [-48, 125].each do |x|
        bounding_box([x, 210], width: 150, height: 80) do
          text invoice.address
        end
      end
    end

    def account_number
      [20, 193].each do |x|
        bounding_box([x, 122], width: 90) do
          pdf.font('Courier', size: 12) { text invoice.account_number }
        end
      end
    end

    def price
      [-50, 123].each do |x|
        bounding_box([x, 96], width: 145) do
          pdf.font('Courier', size: 12) do
            text helper.number_to_currency(invoice.calculated[:total],
                                           format: '%n',
                                           separator: '   '), align: :right
          end
        end
      end
    end

    def esr_number
      bounding_box([300, 146], width: 220) do
        pdf.font('Courier', size: 12) do
          text invoice.esr_number
        end
      end
    end

    def receiver_address
      [[300, 100], [-48, 70]].each do |width, height|
        bounding_box([width, height], width: 150, height: 80) do
          receiver_address_table
        end
      end
    end
  end
end
