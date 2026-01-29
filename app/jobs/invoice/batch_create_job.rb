class Invoice::BatchCreateJob < BaseJob
  self.parameters = [:invoice_run_id, :current_user_id, :invoice_attributes]

  def initialize(invoice_run_id, current_user_id, invoice_attributes)
    super()
    @invoice_run_id = invoice_run_id
    @current_user_id = current_user_id
    @invoice_attributes = invoice_attributes
  end

  def perform
    invoice_run = InvoiceRun.find(@invoice_run_id)
    invoice_run.invoice = Invoice.new(@invoice_attributes)
    Invoice::BatchCreate.new(invoice_run, current_user).call
  end

  private

  def current_user = Person.find(@current_user_id)
end
