// Copyright (c) 2026, Hitobito AG. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito.

// General Javascript dependencies used in all/multiple layouts
// besides application e.g "oauth" or "agenda" in sac wagon

// To reference this file, add "= javascript_pack_tag 'core', 'data-turbo-track': true"
// to the appropriate layout file, like app/views/layouts/application.html.erb

// Polyfills
import 'core-js/stable';
import 'regenerator-runtime/runtime';

// Must run before anything that expects a global jQuery/moment (jquery-ujs,
// jquery-ui, core/wagon coffeescript modules).
import '../javascripts/expose_globals';

// Dependencies
import Rails from 'jquery-ujs';

// jQuery UI
//
// jquery-ui's own files are UMD-wrapped and only declare their internal
// dependencies (e.g. datepicker needing keycode.js, effect-highlight
// needing effect.js) via an AMD `define([...])` array - webpack understood
// that array and bundled the deps automatically, but esbuild (like a real
// browser with no AMD loader) takes the "browser globals" branch of the
// UMD wrapper instead, which assumes those prerequisite files were already
// loaded as globals. So they're imported explicitly here, in dependency
// order, mirroring each file's own `define([...])` list.
import 'jquery-ui/ui/version';
import 'jquery-ui/ui/keycode';
import 'jquery-ui/ui/widgets/datepicker';
import 'jquery-ui/ui/i18n/datepicker-de';
import 'jquery-ui/ui/i18n/datepicker-fr-CH';
import 'jquery-ui/ui/i18n/datepicker-it-CH';
import 'jquery-ui/ui/vendor/jquery-color/jquery.color';
import 'jquery-ui/ui/effect';
import 'jquery-ui/ui/effects/effect-highlight';

// Bootstrap
import 'bootstrap/js/src/alert'
import 'bootstrap/js/src/button'
import 'bootstrap/js/src/collapse'
import 'bootstrap/js/src/dropdown'
import 'bootstrap/js/src/modal'
import Popover from 'bootstrap/js/src/popover'
import 'bootstrap/js/src/scrollspy'
import 'bootstrap/js/src/tab'
import 'bootstrap/js/src/tooltip'
import Tooltip from 'bootstrap/js/dist/tooltip';
import Toast from 'bootstrap/js/src/toast'

window.Popover = Popover
window.Tooltip = Tooltip
window.Toast = Toast

// UI Components
import 'tom-select'

// Turbo
import '@hotwired/turbo-rails';

// Stimulus
import { Application } from "@hotwired/stimulus"

const application = Application.start()
window.Stimulus = application
import "../controllers";

// Custom scripts from core
import "../generated/core_modules";
