# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Invoice
  class Section

    attr_reader :pdf, :invoice, :options

    class_attribute :model_class

    delegate :bounds, :bounding_box, :table,
             :text, :cursor, :font_size, :text_box,
             :fill_and_stroke_rectangle, :fill_color,
             :image, :group, :move_cursor_to, :float,
             :stroke_bounds, to: :pdf

    delegate :recipient, :invoice_items, :recipient_address, :address,
      :with_reference?, :account_number, :participant_number, to: :invoice

    def initialize(pdf, invoice, options={})
      @pdf = pdf
      @invoice = invoice
      @options = options
    end

    private

    def helper
      @helper ||= Class.new do
        include ActionView::Helpers::NumberHelper
      end.new
    end

    def receiver_address_data
      if recipient
        recipient_address_data
      else
        return if recipient_address.blank?
        recipient_address.split(/\n/).map { |ra| [ra] }
      end
    end

    def recipient_address_data
      [
        [recipient.full_name],
        [recipient.address],
        ["#{recipient.zip_code} #{recipient.town}"],
        [Countries.label(recipient.country)]
      ]
    end
  end
end
