# ADR-008 Einsatz von foreign keys auf der DB

Status: **Entscheid**

Entscheid: **Wir verwenden keine Foreign Keys im Applikations Code.**

## Kontext

Referentielle Integrität wird primär über Applikations Code (`dependent: :destroy`, `protective`)
sichergestellt. Vereinzelt sind auch foreign key constraints auf Tabellen definiert, die dann beim
speichern eine `InvalidForeignKey` Exception werfen, welche gefangen und behandelt wird.

## Optionen

### Keine Foreign Keys

Bisher sind nur sehr wenige (10) Foreign Keys definiert. Teils gehören diese zu Dritt-Tabellen
(Active Storage), teils sind sie notwendig, weil eine spezielle Konstellation besteht und die in
Rails verfügbaren Möglichkeiten nicht ausreichen. Ansonsten definieren wir jedoch keine weiteren
Foreign Keys.

Die Person#self_registration_reason kann wohl entsprechend umgebaut werden.

## Optionen

### Foreign Keys

Sollten wenn konsistent über alle Tabellen eingesetzt werden. Referentielle Integrität kann so auf
DB Ebene garantiert werden. Mitunter muss mit migrations Aufwand gerechnet werden, falls aktuell
Referentielle Integrität verletzt wird.

Testsetup ges in der DB angelegt werden müssen. sich mitunter aufwendiger, da relationen zwingend
angelegt werden müssen.

## Kommentare/Advice

### ama 2024-07-12

Unabhängig davon, ob foreign keys definiert sind, sollen Framework Methoden (`dependent: :destroy`)
und nicht custom exception handling verwendet werden, um die Referentielle Integrität
sicherzustellen.

Das `protective` gem soll ausgebaut werden.

### mvi 2024-07-14

Foreign Keys, aber nur als DB-Hilfsmittel

Foreign Keys als DB-Constraint finde ich noch genauso sinnvoll wie Unique Indices. Sie sind ein
Hilfsmittel und unterstützen die Konsistenz, sollten aber primär in der DB bleiben. Da sie aber in
der Applikationlogik nicht unbedingt sichtbar sind, müssen die entsprechenden
Framework-Möglichkeiten genutzt werden. Damit sind Foreignkeys lediglich ein weiteres
Sicherheitsnetz, dass in genutzt werden kann, aber nicht muss.

Für FKs spricht, dass man meist ohnehin Indices auf den Fremdschlüsseln möchte, da diese für JOINs
verwendet werden. Bei wichtigen Verbindungen kann dies dann auch noch mit einem constraint erweitert
werden, der die Integrität sicherstellt.

### pz/ama/di 2024-08-09

FKs sollten entweder einheitlich (über alle Tabellen) oder garnicht verwendet werden. Ein
teils/teils Ansatz (oder nur für neue Tabellen) ist nicht erwünscht. Der Aufwand für die Migration
aller Tabellen in aller Wagons über sämtliche Umgebungen ist nicht unerheblich und es ist fraglich,
ob wir davon wirklich profitieren. Zudem soll berücksichtigt werden, dass FKs das Testsetup mitunter
erschweren, können
