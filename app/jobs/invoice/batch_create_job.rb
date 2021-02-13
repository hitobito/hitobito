class Invoice::BatchCreateJob < BaseJob
  self.parameters = [:invoice_list_id, :invoice_attributes]

  def initialize(invoice_list_id, invoice_attributes)
    super()
    @invoice_list_id = invoice_list_id
    @invoice_attributes = invoice_attributes
  end

  def perform
    invoice_list = InvoiceList.find(@invoice_list_id)
    invoice_list.invoice = Invoice.new(@invoice_attributes)
    Invoice::BatchCreate.new(invoice_list).call
  end
end
