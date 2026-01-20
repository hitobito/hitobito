# Payments

For each invoice, payments can be registered. Some views show the total amount of the payments and when the last payment has been received. In order for this information to be sortable and to avoid N+1 queries, the invoices need the be loaded with the scope `with_aggregated_payments`.
