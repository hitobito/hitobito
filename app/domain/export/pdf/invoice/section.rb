# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Invoice
  class Section

    attr_reader :pdf, :invoice

    class_attribute :model_class

    delegate :bounds, :bounding_box, :table,
             :text, :cursor, :font_size, :text_box,
             :fill_and_stroke_rectangle, :fill_color,
             :image, :group, :move_cursor_to, :float,
             to: :pdf

    delegate :recipient, :invoice_items, to: :invoice

    def initialize(pdf, invoice)
      @pdf = pdf
      @invoice = invoice
    end

    private

    def receiver_address_table
      receiver_address = [
        [recipient.full_name],
        [recipient.address],
        ["#{recipient.zip_code} #{recipient.town}"],
        [Countries.label(recipient.country)]
      ]
      table(receiver_address, cell_style: { borders: [], padding: [0, 0, 0, 0] })
    end

    def helper
      @helper ||= Class.new do
        include ActionView::Helpers::NumberHelper
      end.new
    end
  end
end
