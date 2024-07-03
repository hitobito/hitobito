# ADR-004 Storage auf S3

Status: **Abgeschlossen**

Entscheid: **Für den Wechsel auf OpenShift4 wollen wir S3 nutzen**

## Kontext

Mit dem Wechsel von OpenShift3 auf OpenShift4 fällt die Möglichkeit weg, ReadWriteMany-PVs zu nutzen. ReadWriteOnce-PVs sind weiterhin möglich.

Dies betrifft die Rails-App und die DelayedJob-Worker. Betroffene Dateien sind
  - grundsätzlich öffentliche Dateien/Useruploads
  - private Dateien, bei denen Rechteprüfungen notwendig sind (angeforderte Exporte, die im Hintergrund erzeugt werden)

## Optionen

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

### mvi 2023-12-13

Das Gem "nochmal" wurde entfernt, da vorerst kein weiterer Wechsel geplant ist.
Die Uploader wurden als Abschluss der CarrierWave-Migration entfernt.
