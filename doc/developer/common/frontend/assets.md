## Frontend & Assets

hitobito bindet JavaScript files, Stylesheets, Bilder und Fonts über [Propshaft](https://github.com/rails/propshaft)
(Rails' Asset Pipeline) ein. Die eigentliche Kompilation übernehmen [esbuild](https://esbuild.github.io/) (via
[jsbundling-rails](https://github.com/rails/jsbundling-rails)) für JavaScript und
[dart-sass](https://sass-lang.com/dart-sass/) (via [cssbundling-rails](https://github.com/rails/cssbundling-rails))
für SCSS. Propshaft selbst kompiliert nichts - es fingerprinted und liefert einfach aus, was in `app/assets/builds`
liegt.

### Funktionsweise

Die Entrypoints liegen in `app/javascript/entrypoints/*.js` bzw. `app/assets/stylesheets/entrypoints/*.scss`,
der restliche Quellcode in `app/javascript/**` bzw. `app/assets/stylesheets/hitobito/**`. `bin/rails assets:precompile` (bzw. im
Hintergrund `yarn build` / `yarn build:css`) kompiliert diese nach `app/assets/builds/<wagon-combination>`, von wo sie Propshaft
wie jede andere Datei unter `app/assets/*` fingerprinted ausliefert.

Zwei rake-Tasks (`lib/tasks/assets.rake`) laufen davor:

* `assets:wagon_css_manifest` schreibt `tmp/wagon_css_manifest.json` mit den
  Stylesheet-Verzeichnissen der aktiven Wagons. `config/build_css.mjs` gibt diese
  dart-sass als `--load-path` mit und sucht darin nach wagon-eigenen Entrypoints.
* `assets:wagon_js_manifest` schreibt `tmp/wagon_js_manifest.json`: eine
  Liste der JS-relevanten Dateien jedes aktiven Wagons. `config/esbuild.mjs`
  liest dieses Manifest und generiert daraus (bei jedem Build neu) explizite
  Import-Listen nach `app/javascript/generated/`, da esbuild keine dynamische,
  Verzeichnis-basierte Import-Auflösung unterstützt.

Beide sind über `Rake::Task[...].enhance([...])` an `css:build` / `javascript:build` gehängt, welche
cssbundling-rails/jsbundling-rails wiederum automatisch in `assets:precompile` und `spec:prepare` einhängen;
`db:test:prepare` hängt `lib/tasks/assets.rake` selbst noch dazu.

### Entwicklung

Lokal:

    rake assets:watch_js
    rake assets:watch_css

(im [Hitobito Development](https://github.com/hitobito/development/) Docker-Setup automatisch über die beiden
`assets_js`- und `assets_css`-Container).

Die Watcher bauen neu, wenn eine Datei ändert, die bereits im Bundle ist. Wird `WAGONS` via `bin/active_wagon`
gewechselt oder kommt ein Controller, ein Entrypoint oder ein Modul *neu dazu* (oder fällt weg), müssen die
Watcher neu gestartet werden.

Einmalig bauen, ohne Watcher: `rake assets:build`.

Der Browser lädt automatisch neu, sobald ein Build fertig ist: `hotwire-livereload` (nur in Development, und nur
im Server-Prozess) beobachtet u.a. `app/assets/builds` und schickt das Reload über ActionCable.

Die Bundles tragen in Production `data-turbo-track="reload"`: Turbo erzwingt
damit einen vollen Reload, wenn sich nach einem Deploy der Fingerprint eines Bundles geändert hat, ein offener
Tab also nicht mit altem JavaScript weiterläuft.

`app/assets/builds` liegt in einem Unterverzeichnis pro Instanz, also pro Wagon-Zusammenstellung (siehe
`WagonAssetsHelper.instance_name`), damit sich Builds verschiedener Zusammenstellungen nicht gegenseitig
überschreiben.

### Eigenheiten bezüglich Wagons

Wagons können:

* zusätzliche JavaScripts haben
* zusätzliche Stylesheets haben
* eigene Header-/Footer-Logos haben
* eigene Bilder einbinden
* eigene, komplett separate Entrypoints haben (JS + SCSS), siehe `hitobito_sac_cas`'s `agenda`-Entrypoint

#### JavaScripts

Ein Wagon kann `app/assets/javascripts/wagon.js.coffee` bereitstellen - dieses wird (sofern der Wagon aktiv ist)
automatisch importiert.

Ein Wagon kann zusätzlich eigene `app/javascript/entrypoints/*.js`-Dateien (eigene Entrypoints) und eigene
Stimulus-Controller unter `app/javascript/controllers/*_controller.js` bereitstellen; diese werden automatisch erkannt und unter
`<wagonname>--<controllername>` registriert.

#### Stylesheets

Im File `app/assets/stylesheets/entrypoints/application.scss` (analog `oauth.scss`, `print.scss`) werden
`hitobito/customizable/_variables.scss`, `_fonts.scss` und `_wagon.scss` eingebunden. Das Stylesheet-Verzeichnis
des aktiven Wagons steht in dart-sass' Load-Path *vor* dem des Cores, daher wird jeweils die Datei des Wagons
genommen, falls er eine hat, und sonst die des Cores. Genau deshalb liegen die Entrypoints in einem eigenen
Verzeichnis: dart-sass löst ein `@import` zuerst relativ zum importierenden File auf, ein Entrypoint neben
`hitobito/` würde also immer die Core-Datei finden. (Ein Wagon kann damit auch jedes andere Core-Partial
überschreiben, indem er dessen Pfad nachbaut - aktuell tut das keiner.)

Ein Wagon kann zudem einen eigenen SCSS-Entrypoint mitbringen
(`app/assets/stylesheets/entrypoints/<name>.scss`, z.B. `agenda.scss` in `hitobito_sac_cas`) - dieser wird
automatisch mitkompiliert und über `stylesheet_link_tag "<name>"` eingebunden. Core-Partials sind darin als
`@import "hitobito/..."` erreichbar, eigene Partials des Wagons über einen eigenen Namespace
(`@import "sac_cas/..."`).

Relative `url()`-Referenzen in Stylesheets (z.B. `url('../../../fonts/x.woff2')` in einem
`hitobito/customizable/_fonts.scss` eines Wagons) funktionieren weiterhin: dart-sass übernimmt `url()`
unverändert in den Output, darum normalisiert `Hitobito::RelativeAssetUrls`
(`lib/hitobito/relative_asset_urls.rb`) sie als Propshaft-Compiler, bevor Propshaft sie auflöst.

#### Bilder und Fonts

Bilder und Fonts aus `app/assets/images` bzw. `app/assets/fonts` eines Wagons werden von Propshaft direkt ausgeliefert;
`config/initializers/assets.rb` registriert die Bild- und Font-Verzeichnisse aller aktiven Wagons *vor* den
Core-eigenen, sodass eine gleichnamige Datei im Wagon Vorrang hat. Überschreiben mehrere Wagons dieselbe Datei,
gewinnt der erste in der Reihenfolge von `Wagons.all`.

Mit den `wagon_image_tag`, `wagon_favicon_tag` und `wagon_image_path` Helpers
(`app/helpers/wagon_assets_helper.rb`) können diese Bilder referenziert werden - bei gleichem Dateinamen wird
automatisch das Bild im Wagon bevorzugt (siehe oben).

#### Logo

Der Logo-Pfad kommt aus den `Settings` (`LayoutHelper#header_logo`). Die Grössen stehen ebenfalls in den
`Settings`, werden aber als CSS Custom Properties ins Layout gerendert, damit das Layout sich der
Grösse des Instanz-Logos anpassen kann.
