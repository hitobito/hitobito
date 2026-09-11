## Frontend & Assets

hitobito bindet JavaScript files, Stylesheets, Bilder und Fonts über [Propshaft](https://github.com/rails/propshaft) (Rails' Asset Pipeline) ein. Die eigentliche Kompilation übernehmen [esbuild](https://esbuild.github.io/) (via [jsbundling-rails](https://github.com/rails/jsbundling-rails)) für JavaScript und [dart-sass](https://sass-lang.com/dart-sass/) (via [cssbundling-rails](https://github.com/rails/cssbundling-rails)) für SCSS. Propshaft selbst kompiliert nichts - es fingerprinted und liefert einfach aus, was in `app/assets/builds` liegt.

### Funktionsweise

Die Quell-Dateien liegen in `app/javascript` (Entry Points unter `app/javascript/packs`). `bin/rails assets:precompile` (bzw. im Hintergrund `yarn build` / `yarn build:css`) kompiliert diese nach `app/assets/builds`, von wo sie Propshaft wie jede andere Datei unter `app/assets/*` fingerprinted ausliefert.

Zwei rake-Tasks (`lib/tasks/assets.rake`) laufen davor:

* `assets:render_scss_entries` rendert die ERB-Anteile der SCSS-Entry-Points (`app/javascript/packs/*.scss.erb`, inkl. wagon-eigener Packs) nach `app/assets/stylesheets_generated/*.scss`, bevor dart-sass sie kompiliert - dart-sass selbst kann kein ERB.
* `assets:wagon_js_manifest` schreibt `tmp/wagon_assets_manifest.json`: eine Liste der JS-relevanten Dateien jedes *aktiven* Wagons (`Wagons.all`, nicht einfach jedes `hitobito_*`-Verzeichnis das gerade ausgecheckt ist). `esbuild.config.js` liest dieses Manifest und generiert daraus (bei jedem Build neu) explizite Import-Listen für Dinge, die unter Webpack per `require.context` dynamisch geschehen sind - esbuild kennt das nicht.

Beide Tasks sind über `Rake::Task[...].enhance([...])` an `css:build` / `javascript:build` gehängt, welche cssbundling-rails/jsbundling-rails wiederum automatisch in `assets:precompile` und `test:prepare`/`db:test:prepare` einhängen.

### Entwicklung

Lokal:

    yarn build --watch
    yarn build:css --watch

(im [Hitobito Development](https://github.com/hitobito/development/) Docker-Setup automatisch über den `Procfile`-Eintrag `assets`).

Ohne Dev-Server (z.B. nach einem `WAGONS`-Wechsel via `bin/active_wagon`): `rake assets:build`
(entspricht `yarn build` + `yarn build:css`).

`app/assets/builds` und `app/assets/stylesheets_generated` liegen pro Wagon-Zusammenstellung
("Wagon-Signatur", siehe `WebpackHelper.wagon_signature`) in einem eigenen Unterverzeichnis, damit
sich Builds verschiedener Zusammenstellungen nicht gegenseitig überschreiben.

### Eigenheiten bezüglich Wagons

Wagons können:

* zusätzliche JavaScripts haben
* zusätzliche Stylesheets haben
* eigene Header-/Footer-Logos haben
* eigene Bilder einbinden
* eigene, komplett separate Packs haben (JS + SCSS), siehe `hitobito_sac_cas`'s `agenda`-Pack

#### JavaScripts und Bilder

Ein Wagon kann `app/assets/javascripts/wagon.js.coffee` bereitstellen - dieses wird (sofern der Wagon aktiv ist) automatisch importiert. Bilder aus `app/assets/images` eines Wagons werden von Propshaft direkt ausgeliefert; `config/initializers/assets.rb` registriert die Bild-Verzeichnisse aller aktiven Wagons *vor* den Core-eigenen, sodass eine gleichnamige Datei im Wagon Vorrang hat.

Mit den `wagon_image_pack_tag`, `wagon_favicon_pack_tag` und `wagon_image_pack_path` Helpers (`app/helpers/webpack_helper.rb`) können diese Bilder referenziert werden - bei gleichem Dateinamen wird automatisch das Bild im Wagon bevorzugt (siehe oben).

Ein Wagon kann zusätzlich eigene `app/javascript/packs/*.js`-Dateien (eigene Entry Points, wie z.B. `agenda.js` in `hitobito_sac_cas`) und eigene Stimulus-Controller unter `app/javascript/controllers/*_controller.js` bereitstellen; diese werden automatisch erkannt und unter `<wagonname>--<controllername>` registriert.

#### Stylesheets

Im File `app/javascript/packs/application.scss.erb` (analog `oauth.scss.erb`, `print.scss.erb`) werden `app/assets/stylesheets/hitobito/customizable/_variables.scss`, `_fonts.scss` und `_wagon.scss` des jeweils aktiven Wagons eingebunden (`WebpackHelper#absolute_wagon_file_paths`) - dies passiert weiterhin im Entry-File, weil in SCSS importierte Files nicht durch ERB verarbeitet werden.

Ein Wagon kann zudem einen eigenen SCSS-Entry-Point mitbringen (`app/javascript/packs/<name>.scss.erb`, z.B. `agenda.scss.erb`) - dieser wird automatisch mitkompiliert und über `stylesheet_link_tag "<name>"` eingebunden.

#### Logo

Im File `app/javascript/packs/application.scss.erb` wird Pfad und Grösse vom Logo von den `Settings` übernommen.
