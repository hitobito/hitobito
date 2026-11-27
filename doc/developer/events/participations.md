# Participations

## Application

```ruby
class Event::Course < Event
  # ...
  self.supports_applications = true
  # ...
```

Unterstützt der assozierte Event Applications, wird für jede Participation ein **Event::Application** entry erstellt:

| Attribut             | Beschreibung          |
| -------------------- | --------------------- |
| priority_1           | Event id mit Prio 1   |
| priority_2           | Event id mit Prio 2   |
| priority_3           | Event id mit Prio 3   |
| approved             | Teilnahme bestätigt ? |
| rejected             | Teilnahme abgelehnt ? |
| waiting_list         | Auf Warteliste ?      |
| waiting_list_comment | Kommentar Warteliste  |

Anmeldungen an einen Anlass müssen dadurch erst durch die Anlassverwaltung bestätigt werden.

Bei Events welche keine Event::Application unterstützen, ist auch kein Application record auf der Participation vorhanden.

## Anmeldung

Die Geschäftslogik einer Anmeldung liegt in Domänenklassen, damit alle Wege der Anmeldung dieselben Regeln verwenden:

| Klasse | Aufgabe |
| ------ | ------- |
| `Event::Registration::PersonCreator` | Erstellt die Person einer externen Anmeldung mit ihren Kontaktangaben, inkl. Pflichtfelder, und der Zustimmung zur Datenschutzerklärung |
| `Event::ParticipantAssigner` | Entscheidet, ob eine neue Teilnahme bei automatischer Zuteilung direkt einen Platz erhält, und vergibt ihn samt Bestätigung |

Bestätigungs- und Benachrichtigungsmails verschickt der Aufrufer, da die Bedingungen dafür vom Weg der Anmeldung abhängen (z. B. "Mail senden", Anmeldung für andere).

### Erweiterung in Wagons

Daten, die eine Person bei einer externen Anmeldung unabhängig vom Weg der Anmeldung erhalten soll, gehören in einen Callback der Domänenklasse:

```ruby
Event::Registration::PersonCreator.after_create do |creator|
  role_class = "#{creator.group.class}::External".constantize
  role_class.create!(group: creator.group, person: creator.person)
end
```

`creator` gibt Zugriff auf `event`, `group` und `person`. Der Callback läuft, sobald die Person gespeichert ist, unabhängig davon, ob danach eine Teilnahme entsteht. Was von der Teilnahme abhängt, gehört nicht in diesen Callback.
