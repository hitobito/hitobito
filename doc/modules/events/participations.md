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
