# Data Model

![Class diagram](_diagrams/messages-abo.svg)

### `MailingList`
The MailingList ("Abo") is the central model in the messages module. It belongs to a group and defines a (potentially dynamic) list of subscribers. Various kinds of messages may be dispatched over a mailing list.

### `Subscription`

Subscriptions are used to define the recipients on a mailing list. Subscriptions can be individual persons or specific roles in groups or events. Role-based subscriptions are resolved to actual people everytime a message is dispatched. Individual persons can also be excluded from a mailing list by an exclude subscription.

### `Message`

A single message sent over a mailing list. This message can be sent via the e-mail address of the mailing list (bulk mail) or generated in the frontend and sent as PDF (letter) or text message. See [Message Types](./message_types.md) for details.

### `MessageRecipient`
Message recipients are created when dispatching a message and used to trace who recivied which messages.  Each `MessageRecipient` also receives a status in which the respective status of the dispatch can be viewed. If a dispatch fails, the status can be used to see which people have not yet received a message.

### `Person`
Person is the central model in Hitobito for persons and companies. The contact data relevant for the message module such as e-mail, telephone number or postal address are also stored on the person.
