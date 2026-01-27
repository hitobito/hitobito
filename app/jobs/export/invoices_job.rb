# frozen_string_literal: true

#  Copyright (c) 2026-2026, Eidgenössischer Jodlerverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::InvoicesJob < Export::ExportBaseJob
  self.parameters = PARAMETERS + [:invoice_ids]

  def initialize(format, user_id, invoice_ids, options)
    super(format, user_id, options)
    @invoice_ids = invoice_ids
  end

  private

  def data
    invoices = Invoice.where(id: @invoice_ids).order(Arel.sql(
      "array_position(ARRAY[?]::int[], invoices.id)", @invoice_ids
    ))

    Export::Pdf::Invoice.render_multiple(invoices, @options.merge({
      async_download_file: async_download_file
    }))
  end
end
