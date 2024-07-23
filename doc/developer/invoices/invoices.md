# Invoices

## `Invoice`

The central model represents the invoice itself, belongs to a group and a person entry and contains one or more invoice items (`InvoiceItem`).

## `InvoiceConfig`

The invoice settings are managed per layer and can be found in the main navigation under **Invoices**. Settings such as sender address, account details and reminder texts can be made here.

## `InvoiceArticle`

The invoice articles can be managed in the main navigation under **Invoices**. These articles can then be inserted when creating an invoice.

## `InvoiceList`

Collective invoices are used to create an invoice for several people. The collective invoices created can be found in the main navigation under **Invoices**.

![Collective invoices](_diagrams/invoices-invoice-list.png)

### `Message::LetterWithInvoice`

In addition to letters, [invoice letters](../messages/README.md#messageletterwithinvoice) can be created for recipients for subscriptions (MailingList). The `Message::LetterWithInvoice` entry is linked to a collective invoice `InvoiceList`.
