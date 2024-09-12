# Dispatch
The dispatcher is responsible for sending the corresponding message type.

## `Messages::DispatchJob`
The generic DispatchJob (DelayedJob) for all message types is used to send the messages.

## `TextMessageDispatch`
When sending via SMS, all recipient numbers are first collected and stored in the MessageRecipients. Then the dispatch takes place via an HTTP Api from Aspsms. A short time later, the acknowledgements of receipt are retrieved via a separate HTTP Api call and the MessageRecipient is updated accordingly with the status.

## `LetterDispatch`
Generates all MessageRecipient entries with the postal address of the recipient. A corresponding PDF is then generated based on these entries.

## Print shop
A print shop has its own access to Hitobito and can therefore download letters for dispatch as PDFs.
