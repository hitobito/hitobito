# Entwurfsentscheidungen

# JSON API

Das JSON-Format folgt den Konventionen von [json:api](http://jsonapi.org).

# ADR-001 Kundenprojekte: App vs. Wagon

Status: Vorschlag

Wie behandeln wir Kundenspezifischen Erweiterungen, welche wenig mit Hitobito zu tun haben, wie z.B. eine simple CRUD-App?
(Es gibt (noch?) keinen allgemeingültigen Entscheid, wir sammeln mal die Argumente dafür und dagegen)

## Kontext

* Der Kunde möchte oft, dass die User möglichst wenige Tools verwenden müssen.
* Wir wollen negative Auswirkungen auf den Core und andere Kunden (z.B. kompliziertere Entwicklung) vermeiden.

## Optionen

### Variante "ab in den Wagon"

* ➕ Look&Feel passt automatisch...
* ➖ ...muss aber nachgezogen werden, wenn L&F im Core ändert
* ➖ Wir müssen aufpassen, dass wir die zusätzlichen Geschäftsfälle nicht eng an das Hitobito-Datenmodell koppeln, damit Änderungen am Core nicht vermeidbare Änderungen am Wagon verursachen (etwa wegen Berechtigung oder so oder weil wir Models überall im Code rumgeben)
* ➖ Es kann ein faktisches Vendor-Lock-In bzgl. Hitobito durch spezifische Erweiterungen entstehen

### Variante "eigene App entwickeln"

* ➕ SSO mit OIDC möglich
* ➕ Saubere Modularisierung
* ➕ Mehr Apps, welche die API benutzen, führen zur Weiterentwicklung derselben -> alle profitieren
* ➖ Zusätzliche Applikation mit Lifecycle, Betrieb(skosten), Deployment...
* ➖ Aufgabengebiet des WV wird komplexer (oder erfordert ein komplett neues Team mit WV und WV-Planung)
* ➖ Jetzt müssen wir plötzlich über die API mit Hitobito integrieren, testen und allenfalls die Releases synchronisieren, mit dem Wagon wäre das einfacher

## Kommentare/Advice

### mvi 2022-02-21

Bei neuen, recht eigenständigen Erweiterungen sollte man versuchen, diese als eigene Anwendung zu implementieren. Je nach Größe der App könnte es ein eigenes Projekt werden oder nur in einem weiteren Deployment neben hitobito laufen.

# ADR-002 Wechsel oder Upgrade des RDBMS

Status: Vorschlag

**Wechsel von MySQL zu PostgreSQL**

## Kontext

Während einiger Deployments gab es Probleme mit den Migrationen. Auf der MT-Instanz laufen sie teilweise parallel, was die Analyse erschwert. Um hier eine klare Abgrenzung zu bekommen, wären Transaktionen für strukturelle Änderungen hilfreich. Weiterhin sind in der aktuell verwendete Version von MySQL nicht immer die passenden Datentypen vorhanden, wodurch die DB eher zum "Dumb Datastore" wird und weniger zur Applikation beitragen kann.

## Optionen

### Wechsel zu PostgreSQL

- ➕ Transaktionen umfassen auch strukturelle Anpassungen, Migrationen sind damit self-contained und können atomar angewandet werden.
- ➕ mehr Datentypen ermöglichen bessere Speicherung von Daten (Boolean, Array-Datentypen)
- ➕ Möglichkeit, FTS ohne Sphinx umzusetzen
- ➖ Applikation muss teilweise angepasst werden
- ➖ Backup muss angepasst werden

## Konsequenzen

Wir können Features von PostgreSQL verwenden:

- Strukturtransaktionen, die im Fehlerfall komplett zurückgerollt werden können
- alle Datentypen als Array (Anwendungsbeispiel: eine Person in mehreren Familien) und auf DB-Ebene auswerten
- echte Booleans (Detail, aber schön)
- JSON-Datentypen, Struktur kann auf DB-Ebene ausgewertet werden
- partial indices (kann zu kleineren und damit schnelleren Indizes führen)
- Volltextsuche (nicht so mächtig wie Sphinx, aber näher an den Daten)

Wir müssen eventuell Wissen über PostgreSQL aufbauen:

- Betrieb (Erfahrung aus anderen Projekten ist vorhanden)
- leicht anderer SQL-Dialekt, näher am Standard, aber eben anders als MySQL

Wir müssen die Anwendung entweder DB-agnostisch machen oder die MySQL-Anpassungen zu PostgreSQL-Anpassungen umschreiben.

## Kommentare/Advice

### tbu 2022-02-18

Wechsel von MySQL zu PostgreSQL im Dev-Setup. App wurde dadurch DB-agnostisch, der Wechsel zu PostgreSQL steht noch aus.

Strategie war "Sprung ins kalte Wasser", es ging recht schnell.

- Anpassungen in Migrationen waren nötig
- direktes SQL, das railsfied werden musste
- Empfehlung: Abfragen besser komplett agnostisch mit AR-Bordmitteln machen, notfalls geht aber SQL, dass auf MySQL und PostgreSQL gleichermaßen funktioniert.
- Zur Anpassung wurde der Quellcode nach SQL-Keywords und "execute" durchsucht.
- Der Prozess war:
  1. DB in development wechseln
  2. App wieder "bootbar" machen
  3. Specs laufen lassen und durchklicken, um Reste zu finden.

# ADR-003 DB as a Service

Status: Entwurf

**Entscheidung noch offen**

## Kontext

Im Zuge des Wechsels zu OpenShift4 und auch potentiell von MySQL zu PostgreSQL könnte man das RDBMS nicht mehr als Teil der Rails-Applikation, sondern als externen Dienst umsetzen.

## Optionen

- managed DB bei VSHN
  - Angebot muss eingeholt werden
  - hitobito wird mehrheitlich bei VSHN betrieben
- managed DB bei ElephantSQL
  - https://www.elephantsql.com/plans.html
  - kann im GCP in Zürich laufen
- selbst eine "DB as a Service" für die hitobito-Instanzen aufbauen
- weiterhin die DB als Teil der Applikation betreiben

## Konsequenzen

Für die Rails-App selbst ist der Wechsel nicht schwer. Schon jetzt ist die DB "über das Netzwerk" angebunden. Es ändert sich lediglich der Weg zur DB. Weiterhin könnte es noch Auswirkungen auf existentes Tooling haben. Alles, was bisher direkt auf die DB zugreift (ops-scripte) muss potentiell angepasst werden.

## Kommentare/Advice

adradvisor

# ADR-004 Storage auf S3

Status: Vorschlag

**Für den Wechsel auf OpenShift4 wollen wir S3 nutzen**

## Kontext

Mit dem Wechsel von OpenShift3 auf OpenShift4 fällt die Möglichkeit weg, ReadWriteMany-PVs zu nutzen. ReadWriteOnce-PVs sind weiterhin möglich.

Dies betrifft die Rails-App und die DelayedJob-Worker. Betroffene Dateien sind
  - grundsätzlich öffentliche Dateien/Useruploads
  - private Dateien, bei denen Rechteprüfungen notwendig sind (angeforderte Exporte, die im Hintergrund erzeugt werden)

## Options

### Storage in S3

### S3 als Storage von geteilten Dateien

Dateien, die von mehreren Pods verwendet werden, werden in S3 des Clusters gespeichert.

- ➕ S3 ist eine bekannte Technologie, es gibt viele Clients
- ➕ Durch die Nutzung des S3 des Cloudbetreibers des Clusters ist der Netzwerkoverhead gering
- ➕ es braucht keine mehrfach gemounteten PVs mehr
- ➖ Die Anwendung muss umgestellt werden
- ➖ Die bisherigen Daten müssen übertragen werden

### Datenaustausch nur noch via HTTP

Kommunikation und Datenaustausch zwischen Pods nur noch über http, DB oder memcached

- ➕ es braucht keine mehrfach gemounteten PVs mehr
- ➖ wir würden s3 neu erfinden
- ➖ die Anwendung muss erweitert werden

### Superpod verwenden

Alles in einen Pod stecken, was miteinander reden muss. Damit könnte man auf ReadWriteOnce-PVs wechseln

- ➕ es braucht keine mehrfach gemounteten PVs mehr
- ➖ Rails und DelayedJob müssen in einem Container laufen
- ➖ Scaling ist nicht mehr möglich
- ➖ Resourcen sind schwer einzustellen

## Konsequenzen

Die bisherigen Uploads müssen übertragen werden. Die Komplexität steigt, weil
die Dateien nicht mehr lokal verfügbar sind und ein weiterer Service
Bestandteil des Setups ist. Die S3-Anbindung erfordert mehrere neue Gems als
dependencies.

### Kosten bei Cloudscale (Stand 2022-02-28)

- Speicherplatz:     0.09 CHF / GB / 30 Tage
- Traffic eingehend: 0
- Traffic ausgehend: 0.02 CHF / GB
- API-Request:       0.005 / 1000 Requests

Für Backups ist damit nur der Speicherplatz relevant.
Für die Useruploads haben wir noch keine Trafficzahlen.

Aktuell ist der Datenverbrauch für Uploads und kurzfristigen Datenaustauschen
zwischen Rails und DelayedJob zwischen 150 MB und 3.2 GB, die meisten sind
deutlich unterhalb 1 GB. Backups sind zwischen 100MB und 2.4 GB, die meisten
sind deutlich unterhalb 1 GB.

Die Speicherplatzkosten wären damit zwischen 0.09 und 5.79 CHF / 30 Tage
Die meisten lägen deutlich näher an 0.10 CHF / 30 Tage.

Beim größten Datenvolumen beobachten wir derzeit
durchschnittlich etwa 5000 Requests pro Tag.

Wenn jeder Download 1 API-Request ist, wären das 0.75 CHF / 30 Tage

Ansonsten sind nennenswerte Requestvolumen eher im Bereich 1000 pro Tag

Bei gleicher Annahme wären das 0.15 CHF / 30 Tage

Die laufenden Kosten sind damit insgesamt eher überschaubar.

## Kommentare/Advice

### tbu 2022-02-18

S3 ist auch mit mehreren Buckets möglich, Rails 6.1 kann mehrere Services
verwenden. Jeder Service hat einen Bucket. Das "nochmal" gem kann aus einem
lokalen Storage in ein S3 migrieren.

Es muss also entweder "nochmal" erweitert werden, um Carrierwave-Upload lesen
zu können, ODER man muss manuell alles von Carrierwave zu ActiveStorage::Local
umwandlen. Unser Uploader::Base definiert auf jedem Uploader ein store_dir,
damit könnte man "nochmal" dazu bringen, es als Lesequelle zu verwenden.

Die Migration führt zu einer kurzen Zeit von broken links. Die konkrete Dauer
muss vorher getestet werden.

Wenn man mehrere ActiveStorage-Stores definiert, kann man den Wechsel per ENV
steuern. Solange der Wechsel nicht komplett abgeschlossen ist, muss man das gem
"nochmal" im Gemfile behalten und auch produktiv deployen.
