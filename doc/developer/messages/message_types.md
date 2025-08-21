# Message Types

![Message Types](_diagrams/messages.svg)

The message model defines the different message types of Hitobito (Single Table Inheritance [STI](https://api.rubyonrails.org/classes/ActiveRecord/Inheritance.html)):

| STI Model | Description |
|------------------------|-------------------|
| `Message::TextMessage` | Text Message (SMS) |
| `Message::Letter` | Letter |
| `Message::LetterWithInvoice` | Invoice letter |
| `Message::BulkMail` | Mailing List Email |
| `Message::BulkMailBounce` | Bounce mail of a previously sent BulkMail |

## `Message::TextMessage`

![Screenshot Letter Creation](_diagrams/text-message.png)

This type is an SMS (text message) and is sent to a person if they have a mobile number.

When sending via SMS, all recipient numbers are first collected and stored in the MessageRecipients. Then the dispatch takes place via an HTTP API from ASPSMS. A short time later, the acknowledgements of receipt are retrieved via a separate HTTP API call and the MessageRecipient is updated accordingly with the status.

## `Message::Letter`

![Screenshot Letter Creation](_diagrams/letter.png)

Letter for mailing which is rendered as a PDF.

Generates all MessageRecipient entries with the postal address of the recipients. A corresponding PDF is then generated based on these entries.

These PDFs can then be downloaded by a print shop employee, who have their own access to Hitobito

## `Message::LetterWithInvoice`

![Screenshot Letter Creation](_diagrams/letter-with-invoice.png)

Letters with additional invoice options (invoice items).

First, the PDF from the LetterDispatch is generated. After that, the Invoices for a given InvoiceList are generated and sent.

## `Message::BulkMail`

Mail message which is sent to a mailing list via email and processed by the [Mail Relay](./mail_relay.md).

## `Message::BulkMailBounce`

If a bulk mail is bounced at the target server, it is sent back to the original sender of the bulk mail. A BulkMailBounce entry is created for this purpose.
