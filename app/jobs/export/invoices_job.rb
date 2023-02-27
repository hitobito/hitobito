class Export::InvoicesJob < Export::ExportBaseJob
  self.parameters = PARAMETERS + [:invoice_ids]

  def initialize(format, user_id, invoice_ids, options)
    super(format, user_id, options)
    @invoice_ids = invoice_ids
  end

  private

  def data
    invoices = Invoice.where(id: @invoice_ids)
    Export::Pdf::Invoice.render_multiple(invoices, @options.merge({
      async_download_file: async_download_file
    }))
  end
end
