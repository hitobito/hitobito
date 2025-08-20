## Verteilungssicht

Die als einzelne Server oder Container aufgeteilten Komponenten stellen die Verteilung bei Puzzle dar.
Diese muss nicht zwingend so aufgeteilt werden.

![Verteilungssicht](diagrams/verteilungssicht.svg)


**Puma**: Web Applikationscontainer, welcher die Ruby on Rails Rack Applikation enthält. Nimmt
Anfragen von Web Clients entgegen und beantwortet diese.

**Workers**: Ein oder mehrere Worker Prozesse, welche die `Delayed::Jobs` abarbeiten. Die Jobs
werden vom Rails Prozess in der Datenbank persistiert und zu gegebenen Zeitpunkt von Delayed::Jobs
wieder geladen und ausgeführt.

**Memcached**: In-Memory Store, welcher zum Caching bestimmter Daten verwendet wird.

**Storage**: Hochgeladene Bilder und andere Dateien werden im Filesystem oder in einem S3 Object Storage abgelegt und von dort wieder über den Webserver publiziert.

**Datenbank**: Relationale Datenbank für alle persistenten Daten. In der Regel eine Postgres Datenbank,
welche auf einem separaten Server läuft.

**Mail Sender**: Beliebiger Mail Sender Prozess, welcher für das Versenden von E-Mails verwendet
wird. Die meisten E-Mails werden aus den Workers heraus gesendet. In der Regel ein Sendmail oder SMTP Server.

**Mail Server**: Ein beliebiger Mail Server, welcher eingehende E-Mails an beliebige Adressen einer
Domain über Pop3 oder IMAP abrufbar macht. Wird für die Mailing Listen verwendet, welche die E-Mails
regelmässig von den Workers aus abrufen und weiterleiten. Der ursprüngliche E-Mail Empfänger Name
(z.B. *my_list* bei my_list@mydomain.example.com) wird vorteilhafterweise in einen speziellen Header
(z.B. `X-Original-To`) gesetzt, damit ein E-Mail korrekt einer Mailing Liste zugeordnet werden kann.
Läuft in der Regel auf einem separaten Server.

**Airbrake/Sentry**: Externer Service, welcher in einem Fehlerfall mit allen wichtigen Informationen
benachrichtigt wird. Ist im Diagram nicht dargestellt.

**Prometheus**: Externer Service, welche über einen `rails-metrics-exporter` Prozess verschiedene Metriken zu Web Requests und Hintergrundjobs sammelt. Ist im Diagram nicht dargestellt.
