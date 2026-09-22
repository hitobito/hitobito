# Optionale Features (Feature Gates)

Hitobito enthält optionale Features, die per Feature Gate ein- oder ausgeschaltet werden können.

## Konfiguration

Ein Gate wird über einen `enabled`-Key in `config/settings.yml` gesteuert und kann pro Instanz
in den `settings.yml` der Wagons überschrieben werden.

```yaml
# settings.yml eines Wagons
address:
  company:
    enabled: false
```

Die Gates werden beim Start der Applikation ausgewertet. Änderungen an den Settings erfordern
daher einen **Neustart** der Applikation (inkl. Delayed-Job-Worker).

## Liste der Feature Gates

### Personen

- **`people.cleanup_job`** (Default: `false`) — Periodischer Cleanup-Job, der Personen
  nach konfigurierbaren Kriterien (`cleanup_cutoff_duration`) automatisch aufräumt.
- **`people.minimization`** (Default: `false`) — Datenminimierung für Personen. Erlaubt,
  Personen datensparsam zu "minimieren" statt sie vollständig zu löschen. Relevant für
  Datenschutz-Konzepte mit Aufbewahrungsfristen.
- **`people.family_members`** (Default: `true`) — Familienmitglieder auf Personen.
  Personen können als Geschwister verknüpft werden; die Verknüpfungen werden auf der
  Person angezeigt und beim Zusammenführen und Löschen mitberücksichtigt. Unabhängig
  vom Haushalts-Mechanismus (gemeinsame Adresse via `household_key`).
- **`people.people_managers`** (Default: `false`) — PeopleManager: Personen können andere
  Personen verwalten (z.B. Eltern ihre Kinder oder Vormunde ihre Schützlinge). Manager
  sehen und bearbeiten die verwalteten Personen in ihrem eigenen Konto.
- **`people.people_managers.self_service_managed_creation`** (Default: `false`) —
  Erweiterung zu `people.people_managers`: Verwaltete Personen können im Self-Service
  (z.B. bei der Anlass-Anmeldung) direkt neu angelegt werden, ohne dass ein Manager
  sie vorher erfassen muss.
- **`people.search_by_id`** (Default: `true`) — Personensuche auch nach ID. In der
  globalen Suche kann eine Person direkt über ihre Datenbank-ID gefunden werden. Hilfreich
  für Support und Administration.
- **`personal_documents`** (Default: `false`) — Dokumenten-Upload auf Personen.
  Dateien (z.B. Verträge, Ausweise) können mit Labels versehen auf der Person abgelegt
  werden; sichtbar nur für die Person selbst und Admins.

### Adressen

- **`additional_address`** (Default: `true`) — Zusätzliche Adressen auf Personen und Gruppen.
  Neben der Hauptadresse können beliebig viele weitere Adressen erfasst werden, z.B. eine
  abweichende Rechnungsadresse oder ein Zweitwohnsitz. Jede Adresse erhält eine Kategorie
  (standardmässig «Rechnungsadresse» und «Andere») sowie eigene Namens- und Firmenfelder.
- **`address.company`** (Default: `true`) — Firmenbezug auf Adressen. Auf der Hauptadresse
  können Personen als Firma markiert und mit einem Firmennamen versehen werden; auf
  zusätzlichen Adressen stehen entsprechende Organisationsfelder zur Verfügung. Für
  Organisationen ohne Firmenkonzept (z.B. reine Personenverzeichnisse) kann das Gate
  deaktiviert werden — die Felder verschwinden dann aus Formularen, Filtern und der Suche.
- **`address_sync`** (Default: `false`) — Adress-Synchronisation mit der Swiss Post.
  Adressen von Personen können gegen die Post-Datenbank geprüft und korrigiert werden
  (Schreibweise, Zustellbarkeit). Erfordert einen API-Zugang der Post.

### E-Mail und Kommunikation

- **`email.bounces`** (Default: `true`) — Bounce-Handling für Bulk-Mails. Unerreichbare
  Empfängeradressen werden erkannt und nach einer konfigurierbaren Anzahl Bounces
  (`block_threshold`) für den weiteren Versand blockiert. Schützt die
  Sender-Reputation des Mailservers.
- **`mailchimp`** (Default: `true`) — Mailchimp-Integration für Abos. Abonnentenlisten
  können mit Mailchimp-Audiences synchronisiert werden, um Newsletter-Versand über
  Mailchimp zu ermöglichen.

### Gruppen

- **`groups.statistics`** (Default: `true`) — Statistiken auf Gruppen, z.B.
  Mitgliederzahlen nach Rollentyp, aufbereitet als Übersicht im Gruppen-Tab.
- **`groups.nextcloud`** (Default: `false`) — Nextcloud-Integration: Gruppen können mit
  Nextcloud-Gruppen/-Ordnern verknüpft werden.
- **`groups.period_invoice_templates`** (Default: `false`) — Periodische
  Rechnungsvorlagen auf Gruppen. Wiederkehrende Rechnungen (z.B. Mitgliederbeiträge)
  können als Vorlage definiert und periodisch ausgelöst werden.

### Rechnungen

- **`invoices.filter_by_finance_layer`** (Default: `true`) — Rechnungsliste auf der
  Person wird auf die Finance-Layer eingeschränkt, auf die der aktuelle Benutzer
  Zugriff hat. Bei Deaktivierung sieht der Benutzer alle Rechnungen der Person
  (Verhalten vor #4277).

### Sonstiges

- **`custom_dashboard_page`** (Default: `false`) — Eigene Dashboard-Seite: Statt der
  Standard-Startseite kann eine instanzspezifische Dashboard-Seite konfiguriert werden.

## Spezielle Gates

Diese Gates werden nicht (nur) über `settings.yml` gesteuert:

| Gate | Gesteuert durch |
|------|-----------------|
| `self_registration_reason` | Aktiv, sobald mindestens ein `SelfRegistrationReason` in der DB existiert |
| `self_registration_company` | `Wizards::Steps::NewUserForm.support_company` (Wagon-abhängig) |
