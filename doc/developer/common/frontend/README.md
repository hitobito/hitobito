# Frontend

Dokumentation rund um Webpack, Assets und Wagon Extensions befindet sich [hier](webpacker.md)

## Custom JS Code

ist aktuell unter **[app/javascript/modules](https://github.com/hitobito/hitobito/tree/master/app/javascript/javascripts/modules)** in Modules organisiert. Diese Modules sind mit https://coffeescript.org/ geschrieben.

Längerfristig wollen wir aber auf Vanilla JS (Default Javascript) setzen und Coffeescript Code aus Hitobito entfernen.

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

Eine Konfiguration zu tom-select ist hier: https://github.com/hitobito/hitobito/blob/master/app/javascript/javascripts/modules/tom_select.js
Eine weitere (für remote fetch und multiselect) befindet sich hier: https://github.com/hitobito/hitobito/blob/master/app/javascript/controllers/tom_select_controller.js

### autocomplete.js

autcomplete.js wird in verschiedenen Suchfeldern verwendet, um Vorschläge anzuzeigen.

https://tarekraafat.github.io/autoComplete.js/#/

`autocomplete.js` wird z.B. bei der oberen Suchleiste verwendet.

Die Konfigurationzu autocomplete.js ist hier: https://github.com/hitobito/hitobito/blob/master/app/javascript/javascripts/modules/remote_autocomplete.js

### nested_form gem

For nested forms we use the [nested_form](https://github.com/ryanb/nested_form) gem.

Nested forms are forms where the user can add and remove entries dynamically e.g. the event questions or the further e-mails of a user. 

To implement nested forms you can use the `nested_fields_for` form helper defined in https://github.com/hitobito/hitobito/blob/master/app/helpers/standard_form_builder.rb

For the autocomplete and tooltips to work with the nested forms we override the insertFields function of the gem here:
https://github.com/hitobito/hitobito/blob/master/app/javascript/javascripts/modules/remote_autocomplete.js

## Jquery

aktuell verwenden wir Jquery in der Version 1.12.4

längerfristig soll Jquery komplett aus Hitobito entfernt werden.

Jquery UI ist in der Version 1.12.1 vorhanden. Auch diese Abhängigkeit soll komplett ersetzt werden.

## Icons

Für Icons wird Font-Awesome free 5.x verwendet.

https://github.com/FortAwesome/Font-Awesome

Der Katalog der verfügbaren Icons gibt's hier: https://fontawesome.com/v5/search?m=free

## Fonts

Hitobito verwendet den Font [Noto Sans Latin-Greek-Cyrillic](https://github.com/notofonts/latin-greek-cyrillic) für das Frontend und für die PDF-Generierung. Die font Dateien befinden sich unter `app/javascript/fonts`.

Aktualisieren der Noto Sans Font-Dateien:

1. Aktuelles Release herunterladen von https://github.com/notofonts/latin-greek-cyrillic/releases
2. Zip-Datei entpacken und die alten Dateien in `app/javascript/fonts` durch die neuen ersetzen
3. `woff2_compress NotoSans-Regular.ttf` ausführen, um die `woff2` Datei zu generieren  
   (das `woff2_compress` Binary wird durch das `woff2` Paket bereitgestellt)
