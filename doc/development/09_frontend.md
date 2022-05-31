# Frontend

Dokumentation rund um Webpack, Assets und Wagon Extensions befindet sich [hier](09_frontend/01_webpacker.md)

## Custom JS Code

ist aktuell unter **[app/javascript/modules](https://github.com/hitobito/hitobito/tree/master/app/javascript/javascripts/modules)** in Modules organisiert. Diese Modules sind mit https://coffeescript.org/ geschrieben.

Längerfristig wollen wir aber auf Vanilla JS (Default Javascript) setzen und Coffeescript Code aus Hitobito entfernen.

## Bootstrap

### 2.3.2

Aktuell verwenden wir einige Komponenten aus Bootstrap 2.3.2:

npm package: bootstrap-sass: 2.3.2

[package.json](https://github.com/hitobito/hitobito/blob/master/package.json#L13)

[javascript componenten](https://github.com/hitobito/hitobito/blob/master/app/javascript/packs/application.js#L38)
```
bootstrap-transition
bootstrap-alert
bootstrap-button
bootstrap-collapse
bootstrap-dropdown
bootstrap-tooltip
bootstrap-popover
bootstrap-typeahead
bootstrap-tab
bootstrap-modal
```

[css componenten](https://github.com/hitobito/hitobito/blob/master/app/javascript/stylesheets/vendor/bootstrap.scss)
```
@import "~bootstrap-sass/lib/variables"; // Modify this for custom colors, font-sizes, etc
@import "~bootstrap-sass/lib/mixins";

// CSS Reset
@import "~bootstrap-sass/lib/reset";

// Grid system and page structure
@import "~bootstrap-sass/lib/scaffolding";
@import "~bootstrap-sass/lib/grid";
@import "~bootstrap-sass/lib/layouts";
...
```

### bootstrap-chosen

bootstrap compatibility for chosen-js: https://github.com/harvesthq/chosen

`Chosen is a jQuery plugin that makes long, unwieldy select boxes much more user-friendly.`

http://github.com/alxlit/bootstrap-chosen

[CSS](https://github.com/hitobito/hitobito/blob/master/app/javascript/stylesheets/vendor/chosen-bootstrap.scss)

`chosen-select` wird in diversen Formularen verwendet. z.B. Personen Filter -> Tags

### Bootstrap Grid v4.1.3

https://github.com/hitobito/hitobito/blob/master/app/javascript/stylesheets/vendor/bootstrap-grid.css

wurde von hier kopiert: https://github.com/dmhendricks/bootstrap-grid-css

wird nur wenig verwendet (geprüft im core): people/_attrs sowie messages/_attrs

## Jquery

aktuell verwenden wir Jquery in der Version 1.12.4

längerfristig soll Jquery komplett aus Hitobito entfernt werden. Die aktuelle Bootstrap Version benötigt Jquery.

Jquery UI ist in der Version 1.12.1 vorhanden. Auch diese Abhängigkeit soll komplett ersetzt werden. (z.B. mit Bootstrap 5)
