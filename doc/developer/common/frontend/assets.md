## Frontend & Assets

hitobito bindet JavaScript files, Stylesheets, Bilder und Fonts über [Propshaft](https://github.com/rails/propshaft)
(Rails' Asset Pipeline) ein. Die eigentliche Kompilation übernehmen [esbuild](https://esbuild.github.io/) (via
[jsbundling-rails](https://github.com/rails/jsbundling-rails)) für JavaScript und
[dart-sass](https://sass-lang.com/dart-sass/) (via [cssbundling-rails](https://github.com/rails/cssbundling-rails))
für SCSS. Propshaft selbst kompiliert nichts - es fingerprinted und liefert einfach aus, was in `app/assets/builds`
liegt.

### Funktionsweise

Die Entrypoints liegen direkt in `app/javascript/*.js` (JavaScript) bzw. `app/assets/stylesheets/*.scss.erb`
(SCSS), der restliche Quellcode in den Unterverzeichnissen davon. `bin/rails assets:precompile` (bzw. im
Hintergrund `yarn build` / `yarn build:css`) kompiliert diese nach `app/assets/builds`, von wo sie Propshaft wie
jede andere Datei unter `app/assets/*` fingerprinted ausliefert.

Drei rake-Tasks (`lib/tasks/assets.rake`) laufen davor:

* `assets:render_scss_entries` rendert die ERB-Anteile der SCSS-Entrypoints
  (`app/assets/stylesheets/*.scss.erb`, inkl. wagon-eigener Entrypoints) nach
  `app/assets/stylesheets_generated/`, bevor dart-sass sie kompiliert - dart-sass
  selbst kann kein ERB.
* `assets:wagon_scss_load_paths` schreibt `tmp/wagon_scss_load_paths.json` mit den
  Wurzelverzeichnissen der aktiven Wagons, damit `config/build_css.mjs` diese
  dart-sass als zusätzliche `--load-path` mitgeben kann (nötig, damit `--watch`
  auch Wagon-Dateien überwacht).
* `assets:wagon_js_manifest` schreibt `tmp/wagon_assets_manifest.json`: eine
  Liste der JS-relevanten Dateien jedes *aktiven* Wagons (`Wagons.all`, nicht
  einfach jedes `hitobito_*`-Verzeichnis das gerade ausgecheckt ist).
  `config/esbuild.mjs` liest dieses Manifest und generiert daraus (bei jedem
  Build neu) explizite Import-Listen nach `app/javascript/generated/`, da esbuild
  keine dynamische, Verzeichnis-basierte Import-Auflösung unterstützt.

Alle drei sind über `Rake::Task[...].enhance([...])` an `css:build` / `javascript:build` gehängt, welche
cssbundling-rails/jsbundling-rails wiederum automatisch in `assets:precompile` und `spec:prepare` einhängen;
`db:test:prepare` hängt `lib/tasks/assets.rake` selbst noch dazu.

`app/assets/stylesheets` (dart-sass-Quellen) und `app/assets/stylesheets_generated` werden in
`config/initializers/assets.rb` via `config.assets.excluded_paths` von Propshaft ausgenommen, damit die Quellen
nicht selbst ausgeliefert werden - dasselbe gilt für `app/assets/stylesheets` und `app/assets/javascripts` der
Wagons.

### Entwicklung

Lokal:

    rake assets:watch_js
    rake assets:watch_css

(im [Hitobito Development](https://github.com/hitobito/development/) Docker-Setup automatisch über die beiden
`assets_js`- und `assets_css`-Container).

Einmalig, ohne Watcher (z.B. nach einem `WAGONS`-Wechsel via `bin/active_wagon`): `rake assets:build`.
`bin/rails db:test:prepare` und `rake spec:*` bauen die Assets ebenfalls mit.

Alle diese Tasks führen die oben genannten Prerequisite-Tasks selbst aus; die `yarn`-Scripts direkt aufzurufen
tut das nicht.

`app/assets/builds` und `app/assets/stylesheets_generated` liegen in einem Unterverzeichnis pro Instanz, also
pro Wagon-Zusammenstellung (siehe `WagonAssetsHelper.instance_name`), damit sich Builds verschiedener
Zusammenstellungen nicht gegenseitig überschreiben.

### Eigenheiten bezüglich Wagons

Wagons können:

* zusätzliche JavaScripts haben
* zusätzliche Stylesheets haben
* eigene Header-/Footer-Logos haben
* eigene Bilder einbinden
* eigene, komplett separate Entrypoints haben (JS + SCSS), siehe `hitobito_sac_cas`'s `agenda`-Entrypoint

#### JavaScripts und Bilder

Ein Wagon kann `app/assets/javascripts/wagon.js.coffee` bereitstellen - dieses wird (sofern der Wagon aktiv ist)
automatisch importiert. Bilder aus `app/assets/images` eines Wagons werden von Propshaft direkt ausgeliefert;
`config/initializers/assets.rb` registriert die Bild- und Font-Verzeichnisse aller aktiven Wagons *vor* den
Core-eigenen, sodass eine gleichnamige Datei im Wagon Vorrang hat. Überschreiben mehrere Wagons dieselbe Datei,
gewinnt der erste in der Reihenfolge von `Wagons.all`.

Mit den `wagon_image_tag`, `wagon_favicon_tag` und `wagon_image_path` Helpers
(`app/helpers/wagon_assets_helper.rb`) können diese Bilder referenziert werden - bei gleichem Dateinamen wird
automatisch das Bild im Wagon bevorzugt (siehe oben).

Ein Wagon kann zusätzlich eigene `app/javascript/*.js`-Dateien (eigene Entrypoints) und eigene Stimulus-Controller
unter `app/javascript/controllers/*_controller.js` bereitstellen; diese werden automatisch erkannt und unter
`<wagonname>--<controllername>` registriert.

#### Stylesheets

Im File `app/assets/stylesheets/application.scss.erb` (analog `oauth.scss.erb`, `print.scss.erb`) werden
`app/assets/stylesheets/hitobito/customizable/_variables.scss`, `_fonts.scss` und `_wagon.scss` des jeweils
aktiven Wagons eingebunden (`WagonAssetsHelper#absolute_wagon_file_paths`) - dies passiert weiterhin im
Entry-File, weil in SCSS importierte Files nicht durch ERB verarbeitet werden.

Ein Wagon kann zudem einen eigenen SCSS-Entrypoint mitbringen (`app/assets/stylesheets/<name>.scss.erb`, z.B.
`agenda.scss.erb`) - dieser wird automatisch mitkompiliert und über `stylesheet_link_tag "<name>"` eingebunden.
Core-Partials sind darin als `@import "hitobito/..."` erreichbar, eigene Files des Wagons über den absoluten
Pfad `<%= wagon_path.join(...) %>`.

Relative `url()`-Referenzen in Stylesheets (z.B. `url('../../../fonts/x.woff2')` in einem
`hitobito/customizable/_fonts.scss` eines Wagons) funktionieren weiterhin: dart-sass übernimmt `url()`
unverändert in den Output, darum normalisiert `Hitobito::RelativeAssetUrls`
(`lib/hitobito/relative_asset_urls.rb`) sie als Propshaft-Compiler, bevor Propshaft sie auflöst.

#### Logo

Im File `app/assets/stylesheets/application.scss.erb` wird Pfad und Grösse vom Logo von den `Settings`
übernommen.
