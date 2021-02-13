# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Invoice
  class Section
    attr_reader :pdf, :invoice

    delegate :bounds, :text, :cursor, :font_size, :text_box,
      :fill_and_stroke_rectangle, :fill_color,
      :image, :group, :move_cursor_to, :float,
      :stroke_bounds, to: :pdf

    delegate :invoice_items, :address, :with_reference?, :participant_number, to: :invoice

    def initialize(pdf, invoice, debug = false)
      @pdf = pdf
      @invoice = invoice
      @debug = debug
    end

    private

    def helper
      @helper ||= Class.new do
        include ActionView::Helpers::NumberHelper
      end.new
    end

    def receiver_address_data
      @receiver_address_data ||= tabelize(invoice.recipient_address)
    end

    def tabelize(string)
      string.to_s.split(/\n/).reject(&:blank?).collect { |ra| [ra] }
    end

    def table(table, options)
      pdf.table(table, options) if table.present?
    end

    def bounding_box(top_left, attrs = {})
      pdf.bounding_box(top_left, attrs) do
        yield
        pdf.transparent(0.5) { stroke_bounds } if @debug
      end
    end
  end
end
