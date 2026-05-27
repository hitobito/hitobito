# Übersicht Funktionsweise

## Grundprinzip

Eine **PassDefinition** definiert einen Pass-Typ und wird einer Gruppe zugeordnet. Über **PassGrants** (analog Subscriptions bei Mailing-Listen) wird pro Grantor-Gruppe konfiguriert, welche Rollentypen zur Berechtigung für diesen Pass führen. So kann ein Pass mehrere Gruppen mit unterschiedlichen Rollentypen aggregieren.

Die Berechtigung einer Person wird als **Pass** persistiert (ein Record pro Person+PassDefinition). Dies ermöglicht eine schnelle Anzeige der Pässe auf dem Personenprofil ohne aufwändige SQL-Queries. Pass-Records werden durch Role-Callbacks aktuell gehalten und beim Erstellen einer PassDefinition oder eines PassGrants per Job für alle berechtigten Personen erstellt.

Wenn eine Person einen Pass zu ihrem Wallet hinzufügt, wird eine **PassInstallation** erstellt, die den Installationsstatus im Wallet trackt. Rollenänderungen lösen über Callbacks automatisch eine Aktualisierung des Pass AR-Records und einen Sync zum Wallet-Provider aus.

## Datenmodell

Die zentralen Entitäten und ihre Beziehungen:

| Entität | Beschreibung |
|---|---|
| **PassDefinition** | Definiert einen Pass-Typ, gehört polymorphisch zu einer Group (Event architektonisch vorbereitet). |
| **PassGrant** | Verbindet eine PassDefinition mit einer Grantor-Gruppe und definiert die berechtigenden Rollentypen (via `related_role_types`). |
| **Pass** | Persistierte Berechtigung einer Person für eine PassDefinition (State: eligible/ended/revoked, Gültigkeitsdaten). |
| **PassInstallation** | Trackt einen installierten Pass im Wallet (Provider, Sync-State). Wird erst bei "Add to Wallet" erstellt. |
| **DeviceRegistration** | Trackt Apple-Geräte (n:m zu PassInstallation). Wird von Apples Web-Service-Protokoll benötigt. |
| **PassDecorator** | SimpleDelegator-Decorator für die Pass-Darstellung. Wraps einen Pass AR-Record und liefert Presentation-Logik (QR Code, Logo-Auflösung, Wallet-Daten). Delegiert State-Prädikate (`eligible?`, `ended?`) automatisch an den AR-Record. |
| **Subscribers** | Zentralisiert alle Query-Logik für die Auflösung Person ↔ PassDefinition (analog `MailingLists::Subscribers`). |

Details zu Schema, Validierungen und Scopes: siehe #3956.

## Wallet-Provider-Integration

### Google Wallet

Google speichert Pässe cloud-basiert. Updates werden direkt via REST API an Google gepusht. Flow: Server → Google API → fertig.

### Apple Wallet

Apple-Pässe sind geräte-basiert gespeichert. Pässe werden als signierte `.pkpass`-Dateien (ZIP-Archiv) ausgeliefert. Updates werden indirekt veranlasst: Server → APNs-Push → Gerät → Web-Service → aktualisierte `.pkpass`.

### Technologie-Entscheid

Eigene Implementation für beide Provider statt externer Gems. Begründung und Evaluation: siehe [Architektur-Entscheide und Gem-Evaluation](#architektur-entscheide-und-gem-evaluation).

## Template-System und Wagon-Erweiterbarkeit

Verschiedene Organisationen (SAC, SKV, SWW, etc.) haben unterschiedliche Anforderungen an das Aussehen und den Inhalt ihrer Pässe. Das Template-System ermöglicht es Wagons, jeden Aspekt der Pass-Darstellung anzupassen — ohne den Core-Code zu ändern.

### Grundmechanismus

Eine **TemplateRegistry** verwaltet benannte Template-Bundles. Jedes Bundle besteht aus drei Komponenten:

| Komponente | Zweck | Core-Default |
|---|---|---|
| **PDF-Klasse** | Generiert das PDF-Layout des Passes | `Export::Pdf::Passes::Default` (A6-Landscape) |
| **Pass-View-Partial** | HTML-Template für die QR-Verifizierung und Pass-Ansicht | `"default"` |
| **WalletDataProvider** | Stellt die Daten für Google/Apple Wallet bereit | `Passes::WalletDataProvider` |

Core registriert ein `"default"`-Bundle. Wagons registrieren eigene Bundles in ihrem `config.to_prepare`-Block (z.B. `"sac_membership"`, `"skv_paddle_pass"`). Jede PassDefinition verweist über `template_key` auf ein Bundle.

### WalletDataProvider

Der WalletDataProvider ist die zentrale Schnittstelle für wagon-spezifische Daten. Wagons erstellen eine Subklasse und überschreiben Methoden:

- **`member_number`** — Core-Default: Person-ID zero-padded auf 8 Stellen. SAC überschreibt z.B. mit `person.membership_number`.
- **`member_name`** — Core-Default: `person.full_name`. Wagons können das Format anpassen.
- **`extra_google_text_modules`** — Zusätzliche Text-Blöcke für Google Wallet (z.B. Sektionsname, Qualifikationsstufe).
- **`extra_apple_fields`** — Zusätzliche Felder für Apple Wallet (primary/secondary/auxiliary/back fields).
- **`extra_apple_images`** — Zusätzliche Bilder fürs `.pkpass`-Bundle (z.B. ein Strip-Bild).

### Beispiel: Wagon registriert eigenes Template

```ruby
# hitobito_sac_cas/config/initializers/passes.rb
Rails.application.config.to_prepare do
  Passes::TemplateRegistry.register("sac_membership",
    pdf_class: SacCas::Export::Pdf::Passes::Membership,
    pass_view_partial: "sac_membership",
    wallet_data_provider: SacCas::Passes::MembershipDataProvider
  )
end
```

Wenn nur das `"default"`-Bundle registriert ist, wird das Template-Dropdown im Admin-UI ausgeblendet.

Details: siehe #3989.

## Logo-Auflösung

Jede PassDefinition trägt zwei optionale Logo-Attachments:

- **`logo_icon`** — quadratisches Logo/Signet (1:1). Verwendet für Apple `icon.png`/`thumbnail.png` sowie Google `logo`.
- **`logo_banner`** — Landscape-Banner-Logo (~3:1). Verwendet für Apple `logo.png`, Google `wideLogo`, Pass-Card-View und PDF.

Fallback-Kette für `logo_banner`: PassDefinition-Attachment → Gruppen-Logo aus der Ahnen-Kette → Settings-Fallback. Für `logo_icon` entfällt der Gruppen-Fallback (Group#logo ist ausschliesslich Landscape).

Sprachspezifische Varianten (`logo_banner_de`, `logo_banner_fr` etc.) folgen der `Globalize.fallbacks`-Kette. Apple Wallet bündelt alle Sprachen als `.lproj`-Ordner im `.pkpass`, Google Wallet persistiert die Locale auf `PassInstallation#locale` und nutzt sie bei jedem Sync.

Details: siehe WP 15 (noch kein Ticket).

## Pass-Invalidierung

Zwei Stufen bei Rollenänderungen:

1. **Ablauf** — Rolle bekommt ein Enddatum in der Vergangenheit oder wird archiviert: Pass wird als abgelaufen markiert. Der Wallet-Provider zeigt den Pass visuell als abgelaufen an.
2. **Revokation** — Rolle wird hart gelöscht, keine passenden Rollen mehr vorhanden: Pass wird explizit widerrufen und beim Provider deaktiviert.
