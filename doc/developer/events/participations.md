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

Die Geschäftslogik einer Anmeldung liegt in Domänenklassen, damit Web und andere Wege
(z. B. die JSON:API) dieselben Regeln verwenden:

| Klasse | Aufgabe | Aufgerufen von |
| ------ | ------- | -------------- |
| `Event::Registration::PersonCreator` | Erstellt die Person einer externen Anmeldung: Kontaktangaben (`Event::ParticipationContactData`, inkl. Pflichtfelder und Wagon-Validierungen), Zustimmung zur Datenschutzerklärung | `Event::RegisterController#save_entry` |
| `Event::ParticipantAssigner` | Entscheidet mit `assign_directly?`, ob eine neue Teilnahme bei automatischer Zuteilung direkt einen Platz erhält, und vergibt ihn mit `assign_directly`, was auch die Bestätigung verschickt | `Event::ParticipationsController` (`directly_assign_place?`, `process_created_participation`) |

Die Controller-Methoden bleiben als Hooks bestehen und leiten an die Domänenklassen weiter.
Bestätigungs- und Benachrichtigungsmails verschickt der Aufrufer selbst, da die Bedingungen dafür
vom Weg der Anmeldung abhängen (z. B. "Mail senden", Anmeldung für andere).

### Erweiterung in Wagons

Daten, die eine Person bei einer externen Anmeldung unabhängig vom Weg der Anmeldung erhalten soll,
gehören in einen Callback der Domänenklasse statt in einen Controller-Override:

```ruby
# lib/hitobito_<wagon>/wagon.rb, config.to_prepare
Event::Registration::PersonCreator.after_create do |creator|
  role_class = "#{creator.group.class}::External".constantize
  role_class.create!(group: creator.group, person: creator.person)
end
```

`creator` gibt Zugriff auf `event`, `group` und `person`. Der Callback läuft, sobald die Person
gespeichert ist, unabhängig davon, ob danach eine Teilnahme entsteht: Im Web erstellt eine eigene
Anfrage die Teilnahme, oder die Person bricht vorher ab. Was von der Teilnahme abhängt, gehört
nicht in diesen Callback.
