## Frontend & Assets

hitobito bindet JavaScript files, Stylesheets, Bilder und Fonts über [Propshaft](https://github.com/rails/propshaft)
(die Asset Pipeline von Rails) ein. Die eigentliche Kompilation übernehmen [esbuild](https://esbuild.github.io/) (via
[jsbundling-rails](https://github.com/rails/jsbundling-rails)) für JavaScript und
[dart-sass](https://sass-lang.com/dart-sass/) (via [cssbundling-rails](https://github.com/rails/cssbundling-rails))
für SCSS. Propshaft selbst kompiliert nichts - es fingerprinted und liefert einfach aus, was in
`app/assets/builds` liegt.

### Funktionsweise

Die Entrypoints liegen in `app/javascript/entrypoints/*.js` bzw.
`app/assets/stylesheets/entrypoints/*.scss`, der restliche Quellcode in `app/javascript/**` bzw.
`app/assets/stylesheets/hitobito/**`.

`bin/rails assets:precompile` kompiliert diese nach `app/assets/builds/<wagon-combination>`, von wo
Propshaft sie wie jede andere Datei unter `app/assets/*` fingerprinted ausliefert.

Zwei rake-Tasks (`lib/tasks/assets.rake`) laufen davor:

* `assets:wagon_css_manifest` sucht in den aktiven Wagons die Stylesheet-Verzeichnisse zusammen
  und schreibt sie in `tmp/wagon_css_manifest.json` nieder. `config/build_css.mjs` gibt diese dann
  dart-sass als `--load-path` mit und sucht darin auch nach wagon-eigenen Entrypoints.
* `assets:wagon_js_manifest` sucht in den aktiven Wagons die JS-relevanten Dateien zusammen
  und schreibt sie in `tmp/wagon_js_manifest.json` nieder. ESBuild, konfiguriert in
  `config/esbuild.mjs`, liest dieses Manifest und generiert daraus (bei jedem Build neu) explizite
  Import-Listen nach `app/javascript/generated/`. Diese Listen sind dann im Core in den Entrypoints
  eingebunden.

Beide Tasks sind über `Rake::Task[...].enhance([...])` an `css:build` / `javascript:build` gehängt,
und diese wiederum an `assets:precompile` und `db:test:prepare`. So können die Assets für Produktion
und während dem Test Setup automatisch gebuildet werden. Für die Entwicklung kann man die Builds
watchen lassen, siehe nächstes Kapitel.

### Entwicklung

Lokal:

    rake assets:watch_js
    rake assets:watch_css

(im [Hitobito Development](https://github.com/hitobito/development/) Docker-Setup automatisch über
die beiden `assets_js`- und `assets_css`-Container).

Die Watcher bauen neu, wenn eine Datei ändert, die bereits im Bundle ist. Wird `WAGONS` via
`bin/active_wagon` gewechselt oder kommt ein Controller, ein Entrypoint oder ein Modul *neu dazu*
(oder fällt weg), müssen die Watcher neu gestartet werden.

Der Browser lädt automatisch neu, sobald ein Build fertig ist: `hotwire-livereload` (nur in
Development, und nur im Server-Prozess) beobachtet u.a. `app/assets/builds` und schickt das Reload
über ActionCable.

Einmalig bauen, ohne Watcher: `rake assets:build`. Dies ist aber nur selten mal zum Debuggen nötig.

Die Bundles tragen in ProduKtion `data-turbo-track="reload"`: Turbo erzwingt damit einen vollen
Reload, wenn sich nach einem Deploy der Fingerprint eines Bundles geändert hat, ein offener Tab also
nicht mit altem JavaScript weiterläuft. In Development wollen wir feingranulareren Live Reload,
daher ist das nur in Produktion aktiviert.

Die gebuildeten Assets liegen pro Composition in einem Unterverzeichnis von `app/assets/builds`,
also pro Wagon-Zusammenstellung (siehe `WagonAssetsHelper.instance_name`), damit sich Builds
verschiedener Kunden nicht gegenseitig überschreiben, wenn man mit `bin/active_wagon` arbeitet.

### Eigenheiten bezüglich Wagons

Wagons können:

* zusätzliche JavaScript Dateien haben
* zusätzliche Stylesheets haben
* eigene Header-/Footer-Logos haben
* eigene Bilder einbinden
* eigene, komplett separate Entrypoints haben (JS + SCSS), siehe `agenda`-Entrypoint beim SAC

#### JavaScript

Ein Wagon kann `app/assets/javascripts/wagon.js.coffee` bereitstellen - dieses wird (sofern der
Wagon aktiv ist) automatisch importiert.

Ein Wagon kann zusätzlich eigene `app/javascript/entrypoints/*.js`-Dateien (eigene Entrypoints) und
eigene Stimulus-Controller unter `app/javascript/controllers/*_controller.js` bereitstellen; diese
werden automatisch erkannt und unter `<wagonname>--<controllername>` registriert.

#### Stylesheets

Im File `app/assets/stylesheets/entrypoints/application.scss` (analog `oauth.scss`, `print.scss`)
werden `hitobito/customizable/_variables.scss`, `_fonts.scss` und `_wagon.scss` eingebunden. Das
Stylesheet-Verzeichnis des aktiven Wagons steht im Load-Path von dart-sass *vor* dem des Cores,
daher wird jeweils die Datei des Wagons genommen, falls er eine hat, und sonst die des Cores.

Ein Wagon kann zudem eigene SCSS-Entrypoints anlegen
(`app/assets/stylesheets/entrypoints/<name>.scss`, z.B. `agenda.scss` in `hitobito_sac_cas`). Diese
werden automatisch mitkompiliert und über `stylesheet_link_tag "<name>"` eingebunden. Core-Partials
sind darin als `@import "hitobito/..."` erreichbar, eigene Partials des Wagons über einen eigenen
Namespace (`@import "sac_cas/..."`).

Relative `url()`-Referenzen in Stylesheets (z.B. `url('../../../fonts/x.woff2')`) funktionieren
mit einer Customization an Propshaft. `Hitobito::RelativeAssetUrls` schreibt diese relativen urls
um, da Propshaft + cssbundling-rails das von Haus aus nicht könnte.

#### Bilder und Fonts

Bilder und Fonts aus `app/assets/images` bzw. `app/assets/fonts` eines Wagons werden von Propshaft
direkt ausgeliefert; `config/initializers/assets.rb` registriert die Bild- und Font-Verzeichnisse
aller aktiven Wagons *vor* den Core-eigenen, sodass eine gleichnamige Datei im Wagon Vorrang hat.
Überschreiben mehrere Wagons dieselbe Datei, gewinnt der erste in der Reihenfolge von `Wagons.all`.

Mit den `wagon_image_tag`, `wagon_favicon_tag` und `wagon_image_path` Helpers
(`app/helpers/wagon_assets_helper.rb`) können diese Bilder in HTML eingefügt werden.

#### Logo

Der Logo-Pfad kommt aus den `Settings` (`LayoutHelper#header_logo`). Die Abmessungen stehen
ebenfalls in den `Settings`, und werden als CSS Custom Properties ins Layout gerendert, damit das
Layout sich der Grösse des Instanz-Logos anpassen kann.
