## Asset Management

hitobito verwendet folgende Ansätze für die Einbindung und das Prozessieren der verschiedenen Assets:

- JavaScript/CoffeScript: wird über [jsbundling-rails](https://github.com/rails/jsbundling-rails) mit [esbuild](https://esbuild.github.io/) gebundeled. Die resultierenden Files werden über die Asset Pipeline ([Sprockets](https://github.com/rails/sprockets-rails)) mit einem Hash versehen und eingebunden.
- CSS/SASS: wird über [cssbundling-rails](https://github.com/rails/cssbundling-rails) mit [Dart Sass](https://sass-lang.com/) transpiliert. Die resultierenden Files werden über die Asset Pipeline ([Sprockets](https://github.com/rails/sprockets-rails)) mit einem Hash versehen und eingebunden.
- Bilder & Fonts: werden über die Asset Pipeline ([Sprockets](https://github.com/rails/sprockets-rails)) in das `public/` Directory kopiert und mit einem Hash versehen.

Die allgemeine Funktionsweise des Asset Management und die verschiedenen Ansätze sind im Rails Guide [Asset Pipeline](https://guides.rubyonrails.org/asset_pipeline.html) beschrieben.

### Entwicklung

Lokal können mit folgendem Befehl die Watcher-Prozesse für esbuild & SASS gestartet werden:

    bin/dev

Beim [Hitobito Development](https://github.com/hitobito/development/) Docker Setup wird dieser automatisch gestartet.

Der Server sorgt dafür, dass die Assets gebundelt resp. transpiliert werden. Es ist kein Live Reload möglich bei diesem Ansatz, nach einer JS oder CSS Änderung muss die Seite neu geladen werden.

### Konventionen & Restriktionen

#### Core

- Bilder werden in `app/assets/images`, Fonts in `app/assets/fonts` abgelegt und im CSS mit absolutem Pfad `url("/assets/my-image.jpg")` resp. `url("/assets/my-font.woff2")` referenziert.
- Der Einstiegspunkt für Stylesheets ist `app/assets/stylesheets/application.sass.scss`, in diesem File oder einem der Unterfiles können weitere Importe hinzugefügt werden.
- Zusätzliche Stylesheets können über `stylesheet_link_tag` importiert in `config/initializers/assets.rb` definiert werden.
- Der Einstiegspunkt für JavaScripts ist `app/javascript/application.js`, in diesem File oder einem der Unterfiles können weitere Importe hinzugefügt werden.
- Zusätzliche JavaScripts können über `javascript_include_tag` importiert und in `config/initializers/assets.rb` definiert werden.

#### Wagons

- Bilder werden in `app/assets/images`, Fonts in `app/assets/fonts` abgelegt und im CSS mit absolutem Pfad `url("/assets/my-image.jpg")` resp. `url("/assets/my-font.woff2")` referenziert.
- Weil die Bilder & Fonts vom Core und von den Wagons durch die Asset Pipeline flach ins `public/assets` kopiert werden, müssen Name-Clashes verhindert werden. Wagons sollte also keine Bilder/Fonts haben die gleich heissen wie die Bilder/Fonts im Core.
- Um die SASS Variablen zu customizen, kann `app/assets/stylesheets/hitobito/customizable/_variables.scss` vom Core in den Wagon übernommen und angepasst werden.
- Um die eigene Styles einzuführen, kann im Wagon ein `app/assets/stylesheets/hitobito/customizable/_wagon.scss` File erstellt werden.
- Logo Grösse/Hintergrund und Seitenhintergrund kann im `config/settings.yml` angepasst werden.

### Funktionsweise

#### CSS & Bilder/Fonts

- Die Stylesheets, Bilder & Fonts befinden sich im `app/assets` Verzeichnis.
- Mit dem cssbundling-rails Ansatz wird bei einem `rails assets:precompile` (Build) bzw. bei einem `bin/dev` (Entwicklung) der NPM Task `yarn build:css` ausgeführt.
- Als Vorbereitsschritt (`prebuild:css`) wird beim `yarn build:css` NPM Task der Rake Task `rails generate_dynamic_files` ausgeführt. Dieser schreibt im `app/assets/stylesheets/dynamic` Verzeichnis folgenden Files, welche in den `app/assets/stylesheets/*.sass.scss` Files importiert werden:
  - `base_variables.sass.scss`: Definiert SASS Variablen mit Logo Grösse/Hintergrund und Seitenhintergrund (Quelle sind die Werte aus `config/settings.yml`).
  - `wagon_variables.sass.scss`: Bindet die `app/assets/stylesheets/hitobito/customizable/_variables.scss` Files aller Wagons ein, oder das ensprechende Fallback aus dem Core.
  - `wagon_fonts.sass.scss`: Bindet die `app/assets/stylesheets/hitobito/customizable/_fonts.scss` Files aller Wagons ein, oder das ensprechende Fallback aus dem Core.
  - `wagon_styles.sass.scss`: Bindet die `app/assets/stylesheets/hitobito/customizable/_fonts.scss` Files aller Wagons ein, oder das ensprechende Fallback aus dem Core.
- Der `yarn build:css` NPM Task selber transpiliert dann SASS mit Hilfe von Dart Sass nach `app/assets/builds/*.css`.
- Die Asset Pipeline selber hashed dann die CSS Files und Bilder/Fonts und kopiert sie ins `public/assets` Verzeichnis.
- Im Anschluss wird der Rake Task `rails assets:rewrite_css_urls` ausgeführt, welcher die `url(...)` Werte mit lokalen Pfaden auf den effektiven Filenamen (inkl. Hash) umschreibt. 
- Das resultierende CSS File wird über `stylesheet_link_tag` im Template eingebunden.

#### JavaScript

- Die JavaScript Files befinden sich im `app/javascript` Verzeichnis.
- Mit dem jsbundling-rails Ansatz würd bei einem `rails assets:precompile` (Build) bzw. bei einem `bin/dev` (Entwicklung) der NPM Task `yarn build` ausgeführt.
- Als Vorbereitsungsschritt (`prebuild`) wird beim `yarn build` NPM Task der Rake Task `rails javascript:generate_dynamic_files` asugeführt. Dieser schreibt im `app/javascript/dynamic` Verzeichnis folgenden Files, welche im `app/javascript/application.js` importiert werden:
  - `gems.js` bindet Scripts von legacy Gems ein.
  - `wagon.js` bindet die custom Scripts der Wagons ein.
- Der `yarn build` NPM Task erstellt mit Hilfe von esbuild die JavaScript Bundles nach `app/assets/builds/*.js`.
- Die Asset Pipeline hashed die JS Files und kopiert sie ins `public/assets` Verzeichnis.
