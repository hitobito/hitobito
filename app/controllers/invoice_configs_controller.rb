class InvoiceConfigsController < CrudController

  self.nesting = Group
  self.permitted_attrs = [:payment_information, :address, :iban, :account_number]


  private

  def entry
    parent.invoice_config
  end

  def authorize_class
    authorize!(:create, parent.invoices.build)
  end

  def path_args(_)
    [parent, :invoice_config]
  end
end
