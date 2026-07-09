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

// Dependencies
import 'jquery';
import Rails from 'jquery-ujs';
import 'moment'; // used by events/date_period_validator.js.coffee

// jQuery UI
import 'jquery-ui/ui/widgets/datepicker';
import 'jquery-ui/ui/i18n/datepicker-de';
import 'jquery-ui/ui/i18n/datepicker-fr-CH';
import 'jquery-ui/ui/i18n/datepicker-it-CH';
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
import "controllers";

// Custom scripts from core
function requireAll(r) { r.keys().forEach(r); }
requireAll(require.context('../javascripts/modules', true, /\.(js|coffee)$/));
