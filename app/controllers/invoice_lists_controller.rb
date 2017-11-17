class InvoiceListsController < CrudController
  self.nesting = Group
  self.permitted_attrs = [:title,
                          :description,
                          invoice_items_attributes: [
                            :name,
                            :description,
                            :unit_cost,
                            :vat_rate,
                            :count,
                            :_destroy
                          ]]

  skip_authorize_resource
  before_action :authorize

  def new
    respond_to do |format|
      format.html
      format.js do
        assign_attributes if params[:invoice].present?
      end
    end
  end

  def create
    assign_attributes
    entry.recipient = parent.people.first
    succeeded = entry.valid? ? entry.multi_create(parent.people) : [nil]

    if succeeded.all?
      redirect_with(count: succeeded.size, title: entry.title)
    else
      render :new
    end
  end

  def update
    sent_at = Time.zone.today
    due_at = sent_at + parent.invoice_config.due_days.days

    count = invoices.update_all(state: :sent,
                                due_at: due_at,
                                sent_at: sent_at,
                                updated_at: sent_at)

    redirect_with(count: count)
  end

  def destroy
    count = invoices.update_all(state: :cancelled, updated_at: Time.zone.now)
    redirect_with(count: count)
  end

  def show
    redirect_to group_invoices_path(parent)
  end

  def self.model_class
    Invoice
  end

  private

  def list_entries
    super.includes(recipient: [:groups, :roles])
  end

  def invoices
    parent.invoices.where(id: params[:ids])
  end

  def redirect_with(attrs)
    message = I18n.t("#{controller_name}.#{action_name}", attrs)
    key = attrs[:count] > 0 ? :notice : :alert
    redirect_to group_invoices_path(parent), key => message
  end

  def authorize
    authorize!(:create, parent.invoices.build)
  end

end
