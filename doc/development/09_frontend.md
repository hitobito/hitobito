# Frontend

Dokumentation rund um Webpack, Assets und Wagon Extensions befindet sich [hier](09_frontend/01_webpacker.md)

## Custom JS Code

ist aktuell unter **[app/javascript/modules](https://github.com/hitobito/hitobito/tree/master/app/javascript/javascripts/modules)** in Modules organisiert. Diese Modules sind mit https://coffeescript.org/ geschrieben.

Längerfristig wollen wir aber auf Vanilla JS (Default Javascript) setzen und Coffeescript Code aus Hitobito entfernen.

## Bootstrap

## Bootstrap

### 5.2.0

Aktuell verwenden wir einige Komponenten aus Bootstrap 5.2.0:

npm package: bootstrap: 5.2.0

[package.json](https://github.com/hitobito/hitobito/blob/master/package.json#L13)

[javascript componenten](https://github.com/hitobito/hitobito/blob/master/app/javascript/packs/application.js#L38)
```
bootstrap-alert
bootstrap-button
bootstrap-collapse
bootstrap-dropdown
bootstrap-tooltip
bootstrap-scrollspy
bootstrap-popover
bootstrap-tab
bootstrap-modal
```

[css componenten](https://github.com/hitobito/hitobito/blob/master/app/javascript/packs/application.scss.erb)
```
@import "bootstrap/scss/functions";
@import "bootstrap/scss/variables";
@import "bootstrap/scss/maps";
@import "bootstrap/scss/utilities";

...
```

### tom-select

Wir verwenden tom-select für Select Boxen mit Suchfunktion oder Mehrfachauswahl-Checkboxen. Tom select wird auf select Boxen aktiviert, sobald diese die Klasse `tom-select` hat.

https://tom-select.js.org/

`tom-select` wird in diversen Formularen verwendet. z.B. Personen Filter -> Tags

Die Konfigurationzu tom-select ist hier: https://github.com/hitobito/hitobito/blob/master/app/javascript/javascripts/modules/tom_select.js

### autocomplete.js

autcomplete.js wird in verschiedenen Suchfeldern verwendet, um Vorschläge anzuzeigen.

https://tarekraafat.github.io/autoComplete.js/#/

`autocomplete.js` wird z.B. bei der oberen Suchleiste verwendet.

Die Konfigurationzu autocomplete.js ist hier: https://github.com/hitobito/hitobito/blob/master/app/javascript/javascripts/modules/remote_autocomplete.js

## Jquery

aktuell verwenden wir Jquery in der Version 1.12.4

längerfristig soll Jquery komplett aus Hitobito entfernt werden.

Jquery UI ist in der Version 1.12.1 vorhanden. Auch diese Abhängigkeit soll komplett ersetzt werden.

## Icons

Für Icons wird Font-Awesome free 5.x verwendet.

https://github.com/FortAwesome/Font-Awesome

Der Katalog der verfügbaren Icons gibt's hier: https://fontawesome.com/v5/search?m=free
