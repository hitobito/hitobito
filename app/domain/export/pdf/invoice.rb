# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf
  module Invoice

    MARGIN = 2.cm

    class Runner
      def render(invoices, options)
        pdf = Prawn::Document.new(page_size: 'A4',
                                  page_layout: :portrait,
                                  margin: MARGIN)
        customize(pdf)
        invoices.each do |invoice|
          invoice_page(pdf, invoice, options)
          pdf.start_new_page unless invoice == invoices.last
        end
        pdf.render
      end

      private

      def invoice_page(pdf, invoice, options) # rubocop:disable Metrics/MethodLength
        section_options = options.slice(:debug, :stamped)
        if options[:articles]
          sections.each do |section|
            section.new(pdf, invoice, section_options).render
          end
        end

        if options[:payment_slip]
          if invoice.payment_slip == 'qr'
            PaymentSlipQr.new(pdf, invoice, section_options).render
          else
            PaymentSlip.new(pdf, invoice, section_options).render
          end
        end
      end

      def customize(pdf)
        pdf.font_size 10
        pdf.font 'Helvetica'
        pdf.font_families.update('ocrb' => { normal: ocrb_path })
        pdf
      end

      def sections
        [Header, InvoiceInformation, ReceiverAddress, Articles]
      end

      def ocrb_path
        Rails.root.join('app', 'javascript', 'fonts', 'OCRB.ttf')
      end

    end

    mattr_accessor :runner

    self.runner = Runner

    def self.render(invoice, options)
      runner.new.render([invoice], options)
    end

    def self.render_multiple(invoices, options)
      runner.new.render(invoices, options)
    end
  end
end
