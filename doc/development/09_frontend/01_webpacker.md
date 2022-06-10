## Frontend & Assets

hitobito bindet JavaScript files, Stylesheets, Bilder und Fonts via [Webpacker](https://github.com/rails/webpacker) ein, Rails' [Asset Pipeline](https://guides.rubyonrails.org/asset_pipeline.html) (Sprockets) ist nicht aktiv. Webpacker ist eine Integration von des Module Bundlers [Webpack](https://webpack.github.io/) in Rails.

### Funktionsweise

Die Assets befinden sich im `app/assets` Verzeichnis. Im Verzeichnis `app/assets/packs` befinden sich die Entry Points, welche Webpack aufgreift und die schlussendlich zu eigenen Artefakten führen. In den dortigen Files können weitere Ressourcen importiert werden (diese sind in den weiteren Verzeichnissen in `app/assets` abgelegt). Alle Ressourcen, welche mitgebundelt werden sollen (z.B. auch Bilder) müssen in diesen Files (direkt oder via ein weiterer Import) angezogen werden. Bilder welche in CSS via `url(my-image.png)` referenziert werden, werden auch berücksichtigt.

### Entwicklung

Lokal kann der Webpack Development Server gestartet werden:

    bin/webpack-dev-server

Beim [Hitobito Development](https://github.com/hitobito/development/) Docker Setup wird dieser automatisch gestartet.

Der Server sorgt dafür, dass die Assets gebundelt werden und beinhaltet ein Live Reload.

Mit dem folgenden Befehl kann der Inhalt des Production-Bundels eingesehen werden:

    yarn analyze

### Eigenheiten bezüglich Wagons

Wagons können:

* zusätzliche JavaScripts haben
* zusätzliche Stylesheets haben
* eigene Header-/Footer-Logos haben
* eigene Bilder einbinden

#### JavaScripts und Bilder

Im File `app/assets/javascripts/wagons.js.erb` wird das `app/assets/javascripts/wagon.js.coffee` Script des Wagons sowie dessen Bilder in `app/assets/images` importiert.

Mit den `wagon_image_pack_tag` und `wagon_image_pack_path` Helpers können diese Bilder referenziert werden, dabei wird bei gleichem Dateinamen das Bild im Wagon mit Priorität berücksichtigt.

Technisch ist dies ist mit einem eigenen `file-loader` umgesetzt (siehe `config/webpack/loaders/wagon-file.js`), der die Bilder des Wagons unter dem Pfad `/packs/wagon-media/images`, statt `/packs/media/images` zur Verfügung stellt.

#### Stylesheets

Im File `app/assets/packs/application.scss.erb` wird die CSS Files `app/assets/stylesheets/hitobito/customizable/_variables.scss`, `app/assets/stylesheets/hitobito/customizable/_fonts.scss` und `app/assets/stylesheets/hitobito/customizable/_wagon.scss` eingebunden. Dies passiert im Entry File, da in SASS importierte Files nicht durch die Webpack Loaders prozessiert werden und somit dort kein ERB möglich ist.

#### Logo

Im File `app/assets/packs/application.scss.erb` wird Pfad und Grösse vom Logo von den `Settings` übernommen.
