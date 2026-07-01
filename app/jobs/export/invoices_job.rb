# frozen_string_literal: true

#  Copyright (c) 2026-2026, Eidgenössischer Jodlerverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::InvoicesJob < Export::ExportBaseJob
  self.parameters = PARAMETERS + [:invoice_ids]
  self.reports_progress = true

  def initialize(format, user_id, invoice_ids, options)
    super(format, user_id, options)
    @invoice_ids = invoice_ids
  end

  def format_supported?
    %i[pdf csv xlsx].include? @format
  end

  def entries
    Invoice.find_by_ids_keeping_order(@invoice_ids)
  end

  def data
    return if entries.blank?

    case @format
    when :pdf
      Export::Pdf::Invoice.render_in_batches(@invoice_ids, @options.merge({
        job: self
      }))
    when :csv
      Export::Tabular::Invoices::List.csv(entries)
    when :xlsx
      Export::Tabular::Invoices::List.xlsx(entries)
    end
  end
end
