# ADR-008 Einsatz von foreign keys auf der DB

Status: **Vorschlag**

Entscheid: **Offen**

## Kontext

Referentielle Integrität wird primär über Applikations Code (`dependent: :destroy`, `protect_if`)
sichergestellt. Vereinzelt sind auch foreign key constraints auf Tabellen definiert, die dann beim
speichern eine `InvalidForeignKey` Exception werfen, welche gefangen und behandelt wird.

## Optionen

### Keine Foreign Keys

Bisher sind nur sehr wenige (10) Foreign Keys definiert. Teils gehören diese zu Dritt-Tabellen
(Active Storage), teils sind sie notwendig, weil eine spezielle Konstellation besteht und die in
Rails verfügbaren Möglichkeiten nicht ausreichen. Ansonsten definieren wir jedoch keine weiteren
Foreign Keys.

Die Person#self_registration_reason kann wohl entsprechend umgebaut werden.

## Kommentare/Advice

### ama 2024-07-12

Unabhängig davon, ob foreign keys definiert sind, sollen Framework Methoden
(`dependent: :destroy`) und nicht custom exception handling verwendet werden, um die Referentielle
Integrität sicherzustellen.

Das `protect_if` gem soll ausgebaut werden.
