# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf
  module Invoice

    MARGIN = 2.cm

    LOGO_WIDTH = 150.mm
    LOGO_HEIGHT = 16.mm

    class Runner
      def initialize(invoices, async_download_file)
        @invoices = invoices
        @async_download_file = async_download_file
      end

      def render(options)
        pdf = Prawn::Document.new(page_size: 'A4',
                                  page_layout: :portrait,
                                  margin: MARGIN)
        customize(pdf)
        @invoices.each_with_index do |invoice, position|
          reporter&.report(position)
          invoice_page(pdf, invoice, options)
          pdf.start_new_page unless invoice == @invoices.last
        end
        pdf.render
      end

      private

      def reporter
        return unless @async_download_file

        @reporter ||= init_reporter
      end

      def init_reporter
        Export::ProgressReporter.new(
          @async_download_file,
          @invoices.size
        )
      end

      def invoice_page(pdf, invoice, options) # rubocop:disable Metrics/MethodLength
        section_options = options.slice(:debug, :stamped)

        # render logo if logo_position is set to left or right
        if %w[left right].include?(invoice.logo_position)
          render_logo(pdf, invoice, **section_options)
        end

        if options[:articles]
          sections.each do |section|
            section.new(pdf, invoice, section_options).render
          end
        end

        if options[:payment_slip]
          if invoice.payment_slip == 'qr'
            payment_slip_qr_class.new(pdf, invoice, section_options).render
          else
            PaymentSlip.new(pdf, invoice, section_options).render
          end
        end
      end

      # the default payment_slip_qr_class can be overwritten in wagon
      def payment_slip_qr_class
        PaymentSlipQr
      end

      def render_logo(pdf, invoice, **section_options)
        Logo.new(
          pdf,
          invoice.invoice_config.logo,
          image_width: LOGO_WIDTH,
          image_height: LOGO_HEIGHT,
          position: invoice.logo_position.to_sym,
          **section_options
        ).render
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
      async_download_file = options.delete(:async_download_file)
      runner.new([invoice], async_download_file).render(options)
    end

    def self.render_multiple(invoices, options)
      async_download_file = options.delete(:async_download_file)
      runner.new(invoices, async_download_file).render(options)
    end
  end
end
