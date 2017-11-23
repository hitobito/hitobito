module InvoicesHelper

  def format_invoice_state(invoice)
    type = case invoice.state
           when /draft|cancelled/ then 'info'
           when /sent/ then 'warning'
           when /payed/ then 'success'
           when /overdue/ then 'important'
           end
    badge(invoice.state_label, type)
  end

end
