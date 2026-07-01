#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf
  module Invoice
    MARGIN = 2.cm
    BATCH_SIZE = 500

    class Runner
      def initialize(invoices, job)
        @invoices = invoices
        # rubocop:todo Layout/LineLength
        @invoice_config = invoices.first.invoice_config # we assume that all invoices have the same invoice config
        # rubocop:enable Layout/LineLength
        @job = job
        @metadata = {first_pages_of_invoices: [], pages_with_payment_slip: []}
      end

      def render(options)
        build_pdf(options).render
      end

      private

      def build_pdf(options)
        pdf = Export::Pdf::Document.new(margin: MARGIN).pdf
        customize(pdf)

        invoice_count = @invoices.count

        @invoices.each_with_index do |invoice, position|
          LocaleSetter.with_locale(person: invoice.recipient.then {
            _1.is_a?(Person) ? _1 : nil
          }) do
            @job&.report_progress!(position, invoice_count)
            invoice_page(pdf, invoice, options)
            pdf.start_new_page if (position + 1) < invoice_count
          end
        end
        pdf
      end

      def invoice_page(pdf, invoice, options) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
        section_options = options.slice(:debug, :stamped, :reminders)

        @metadata[:first_pages_of_invoices] += [pdf.page_count]

        if options[:articles]
          sections.each do |section|
            section.new(pdf, invoice, section_options).render
          end
        end

        if options[:payment_slip]
          if invoice.payment_slip == "qr"
            payment_slip_qr_class.new(pdf, invoice, section_options).render
            @metadata[:pages_with_payment_slip] += [pdf.page_count]
          else
            PaymentSlip.new(pdf, invoice, section_options).render
          end
        end
      end

      # the default payment_slip_qr_class can be overwritten in wagon
      def payment_slip_qr_class
        PaymentSlipQr
      end

      def customize(pdf)
        pdf.font_size 9
        pdf.font_families.update("ocrb" => {
          normal: Rails.root.join("app", "javascript", "fonts", "OCRB.ttf")
        })
        pdf
      end

      def sections
        [Header, InvoiceInformation, ReceiverAddress, Articles]
      end
    end

    mattr_accessor :runner

    self.runner = Runner

    class << self
      def render(invoices, options)
        unless invoices.is_a?(Array) && invoices.all?(::Invoice)
          raise <<~MSG
            The method render expects an array of invoice objects. This method is only suitable
            for small collections of invoices. Either call to_a on your Active Record relation
            or use render_in_batches with an array of invoice ids.
          MSG
        end

        job = options.delete(:job)

        runner.new(invoices, job).render(options)
      end

      def render_in_batches(invoice_ids, options)
        unless invoice_ids.is_a?(Array) && invoice_ids.all?(Integer)
          raise <<~MSG
            The method render_in_batches expects an array of invoice ids. This method is suitable
            for big collections of invoices but can't be passed an Active Record relation or an
            array of invoices directly. If you want to render a small collection of invoices use
            the method render instead or gather the invoice ids first.
          MSG
        end

        batch_size = options.delete(:batch_size) || BATCH_SIZE

        invoices = ::Invoice.find_in_ordered_batches(invoice_ids, batch_size:)
        job = options.delete(:job)

        runner.new(invoices, job).render(options)
      end
    end
  end
end
