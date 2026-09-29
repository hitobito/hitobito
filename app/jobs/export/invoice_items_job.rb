# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::InvoiceItemsJob < Export::ExportBaseJob
  self.parameters = PARAMETERS + [:invoice_ids]
  self.reports_progress = true

  def initialize(format, user_id, invoice_ids, options)
    super(format, user_id, options)
    @invoice_ids = invoice_ids
  end

  def format_supported?
    %i[csv xlsx].include? @format
  end

  def entries
    # Every row repeats the data of its invoice, so we preload the invoices.
    InvoiceItem.find_in_ordered_batches(invoice_item_ids, scope: InvoiceItem.includes(:invoice))
  end

  def data
    return if @invoice_ids.empty?

    case @format
    when :csv then Export::Tabular::InvoiceItems::List.csv(entries)
    when :xlsx then Export::Tabular::InvoiceItems::List.xlsx(entries)
    end
  end

  private

  def invoice_item_ids
    InvoiceItem.where(invoice_id: @invoice_ids).order(:invoice_id, :id).pluck(:id)
  end
end
