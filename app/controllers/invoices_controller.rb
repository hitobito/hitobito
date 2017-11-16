class InvoicesController < CrudController
  self.nesting = Group
  self.permitted_attrs = [:title, :description, :invoice_items_attributes]

  def destroy
    cancelled = run_callbacks(:destroy) { entry.update(state: :cancelled) }
    set_failure_notice unless cancelled
    respond_with(entry, success: cancelled, location: group_invoices_path(parent))
  end

  private

  def list_entries
    super.includes(recipient: [:groups, :roles]).list
  end

  def authorize_class
    authorize!(:create, parent.invoices.build)
  end

end
