// Copyright (c) 2026, Hitobito AG. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito.

// General Javascript dependencies used in all/multiple layouts besides
// application, e.g. "oauth" or "agenda" in the sac wagon. Referenced via
// "= javascript_include_tag 'core', 'data-turbo-track': true".

// Polyfills
import 'core-js/stable';
import 'regenerator-runtime/runtime';

// Must run first: jquery-ujs/jquery-ui/coffeescript modules expect global jQuery/moment.
import '../javascripts/expose_globals';

// Dependencies
import Rails from 'jquery-ujs';

// jQuery UI
//
// jquery-ui's UMD files declare internal deps (e.g. datepicker needs
// keycode.js) via an AMD define([...]) array, which esbuild - unlike
// webpack - doesn't resolve automatically; so they're imported explicitly
// here, in dependency order.
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
//
// tom-select only sets window.TomSelect in its UMD "browser globals"
// branch, which esbuild's CJS resolution skips - so expose it explicitly.
import TomSelect from 'tom-select'
window.TomSelect = TomSelect

// Turbo
import '@hotwired/turbo-rails';

// Stimulus
import { Application } from "@hotwired/stimulus"

const application = Application.start()
window.Stimulus = application
import "../controllers";

// Custom scripts from core
import "../generated/core_modules";
