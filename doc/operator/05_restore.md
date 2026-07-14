# Restore

> Niemand will Backup, alle wollen Restore!

Damit ein Restore möglich ist, sollte man ein Backup der Datenbank haben. Erfahrungsgemäss reicht ein tägliches Backup aus, um die meisten Datenrettungen erfolgreich (genug) durchzuführen.

## Backup holen und als DB vorbereiten

Sobald man das gewünschte Backupfile hat, sollte man damit ein neue DB aufsetzen.

```bash
> gunzip database.sql.gz
> pg_restore -d $RAILS_DB_NAME -cOx --if-exists database.sql
```

## Daten extrahieren

Zum Extrahieren der Daten aus dem Dump existiert ein Rake-Task, bei weiteren Datenrettungen können das mehr werden.

### Events

Um die Daten vom Event mit der ID 1234 zu extrahieren, reicht dies:

```bash
> RAILS_DB_SCHEMA=database rake restore:export:event[1234] > event.sql
```

Hier wird davon ausgegangen, dass der Restore in ein Schema namens "database" stattgefunden hat. Dies hängt natürlich vom konkreten Setup ab und soll nur zeigen, wie man die Connection anpassen kann.

Das erstellte `event.sql`-Script kann auf der DB angewendet werden, von der die Daten gelöscht wurden. Es enthält alle Daten, die beim Löschen eines Events mitgelöscht wurden und in der DB sind. Es enthält keine Attachments. Die Relationen `subscriptions` und `person_add_requests` sind noch nicht enthalten, da diese bisher nicht wiederhergestellt werden mussten.

### Personen trennen / Duplikate wieder herstellen

Um zusammengeführte Personen wieder zu trennen, kann man diesen Task verwenden:

```bash
> rake restore:export:duplicate[1234] > duplicate.sql
```

Die `id` ist der primary-key des `person_duplicates`-Eintrags aus dem alten Dump. Der Dump muss dazu vorher in die DB, gegen welche der Rake-Task läuft, eingespielt worden sein. Siehe dazu weiter oben "DB vorbereiten".

Es werden verschiedene SQL-Queries ausgegeben, welche direkt auf der produktiven DB angewendet werden können. Den Rake-Task interessiert es nicht, welche Person in welche gemerged wurde, die Queries machen für beide ein "INSERT INTO ... ON CONFLICT ...".

Aktuell werden folgende Associations auch wieder zurückgesetzt:
- Rollen
- Rechnungen
- Notizen
- Event-Kontakt Einträge
- Gruppen-Kontakt Einträge
- Familien
- MailingListen/Abos
- Event-Einladungen
- Event-Teilnahmen
- Gruppen-Anfragen
- Tags
- Qualifikationen
- Zusätzliche E-Mails
- Telefonnummern
- Social Media Einträge

## Daten prüfen und importieren

Das Script sollte gründliche reviewt und idealerweise manuell gegen eine Kopie des Production-Setups getestet werden. Wenn alles stimmt, kann es auf der production-database angewendet werden.

Beispielsweise:

```bash
> cat event.sql | DATABASE_URL="postgres://user@remote-db/production" rails db -p
```

## Aufräumen

Nach der Datenrettung sollten die nun nicht mehr benötigten Backups und Kopien des Production-Setups entfernt werden. Auch das erzeugte Script sollte gelöscht werden.
