#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class Invoices < Base
    delegate :params, to: :template

    def initialize(template, type, invoice: nil)
      super(template, translate(type), type)
      @invoice = invoice
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
      add_item(translate(full_label), export_path(:pdf), **item_options)
      if payment_slip_relevant?
        add_item(translate(:articles_only), export_path(:pdf, payment_slip: false), **item_options)
        add_item(translate(:esr_only), export_path(:pdf, articles: false), **item_options)
      end
      add_item(translate(original_invoice_label), export_path(:pdf, reminders: false),
        **item_options)
    end

    def full_label
      payment_slip_relevant? ? :full : :full_without_payment_slip
    end

    def original_invoice_label
      payment_slip_relevant? ? :original_invoice : :original_invoice_without_payment_slip
    end

    # Whether printing with/without the payment slip separately is a meaningful choice.
    # Without a specific invoice to check (e.g. the bulk print dropdown covering several
    # invoices at once) we cannot know, so the options are shown.
    def payment_slip_relevant?
      @invoice.nil? || !@invoice.no_ps?
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
        export_path(format),
        **item_options
      )
      item.sub_items << Item.new(
        translate(:payments_without_invoice_csv),
        payment_export_path(format, {status: :without_invoice}),
        **item_options
      )
    end

    def item_options
      {data: {checkable: true}}
    end

    def export_path(format, options = {})
      params.merge(options).merge(format: format)
    end

    def payment_export_path(format, options = {})
      template.group_payments_path(
        params.to_unsafe_h.merge(options).symbolize_keys.merge(format: format)
      )
    end
  end
end
