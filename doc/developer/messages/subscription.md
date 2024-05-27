# Subscription
![Class diagram](_diagrams/messages-abo.svg)

Class diagram messages module.

![View group](_diagrams/mailing-lists.png)

_View of the subscriptions of a group_

### E-mail
[Detailed documentation](e-mail/README.md)

### `Person`
Person is the central model in Hitobito for persons and companies. The contact data relevant for the message module such as e-mail, telephone number or postal address are also stored on the person.

### `MailingList`
The subscription (MailingList) is one of the central elements in the Messages module. Subscriptions are used to define the recipients on a subscription. Subscribers can be groups and specific roles as well as individual persons.


### `MessageRecipient`
The `MessageRecipient` is created in the `Dispatch` as soon as a message is sent. This consists of the persons and the message which are sent. Each `MessageRecipient` also receives a status in which the respective status of the dispatch can be viewed. If a dispatch fails, the status can be used to see which people have not yet received a message.
