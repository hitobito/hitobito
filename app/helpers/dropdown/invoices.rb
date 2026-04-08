#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class Invoices < Base
    delegate :params, to: :template

    def initialize(template, type)
      super(template, translate(type), type)
    end

    def print
      pdf_links
      self
    end

    def export
      label_links
      add_export_links(:csv)
      add_export_links(:xlsx)
      self
    end

    def user = template.current_user

    private

    def pdf_links
      add_item(translate(:full), export_path(:pdf), **item_options)
      add_item(translate(:articles_only), export_path(:pdf, payment_slip: false), **item_options)
      add_item(translate(:esr_only), export_path(:pdf, articles: false), **item_options)
      add_item(translate(:original_invoice), export_path(:pdf, reminders: false), **item_options)
    end

    def label_links
      if LabelFormat.exists?
        Dropdown::LabelItems.new(self, item_options.merge(household: false)).add
      end
    end

    def add_export_links(format)
      item = add_item(translate(format), "#")
      item.sub_items << Item.new(
        Invoice.model_name.human(count: 2),
        export_path(format)
      )
      item.sub_items << Item.new(
        translate(:payments_without_invoice_csv),
        payment_export_path(format, {state: :without_invoice})
      )
    end

    def csv_links
      add_item(translate(:csv), export_path(:csv), **item_options)
      add_item(translate(:payments_without_invoice_csv),
        payment_export_path(:csv, {state: :without_invoice}))
    end

    def item_options
      {data: {checkable: true}}
    end

    def export_path(format, options = {})
      params.merge(options).merge(format: format)
    end

    def payment_export_path(format, options = {})
      template.group_payments_path(params.to_unsafe_h.merge(options).merge(format: format))
    end
  end
end
