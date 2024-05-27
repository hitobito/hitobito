# Events

![Modulübersicht](_diagrams/events-overview.svg)

Hitobito besitzt ein vielseitiges System um Anlässe (Event) und Kurse (Event::Course) zu verwalten. Im pbs und jubla Wagon gibt es auch noch eine Erweiterung für Lager (Event::Camp).

Viele Event Features sind in den Wagons customized, diese Dokumentation bezieht sich hauptsächlich auf die Features im Core und beschreibt teilweise die vorhandenen Wagon-Erweiterungen.

## Participations

Personen (Person) werden via [Participations](participations.md) (Participation) an Events angemeldet.

## Kurse

Bereits im Core existiert das STI Model Event::Course.

## Optional Features
* [Waiting List](optional_features/waiting-list.md)
