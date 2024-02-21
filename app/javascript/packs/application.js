/* eslint no-console:0 */

/**
 * Copyright (c) 2020, hitobito AG. This file is part of
 * hitobito and licensed under the Affero General Public License version 3
 * or later. See the COPYING file at the top-level directory or at
 * https://github.com/hitobito/hitobito.
 */

// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

import 'core-js/stable';
import 'regenerator-runtime/runtime';

/**
 * Dependencies
 */
import 'jquery';
import Rails from 'jquery-ujs';
import 'moment'; // used by events/date_period_validator.js.coffee

// jQuery UI
import 'jquery-ui/ui/widgets/datepicker';
import 'jquery-ui/ui/i18n/datepicker-de';
import 'jquery-ui/ui/i18n/datepicker-fr';
import 'jquery-ui/ui/i18n/datepicker-it';
import 'jquery-ui/ui/effects/effect-highlight';

// Bootstrap
import 'bootstrap/js/src/alert'
import 'bootstrap/js/src/button'
// import 'bootstrap/js/src/carousel'
import 'bootstrap/js/src/collapse'
import 'bootstrap/js/src/dropdown'
import 'bootstrap/js/src/modal'
import  Popover  from 'bootstrap/js/src/popover'
import 'bootstrap/js/src/scrollspy'
import 'bootstrap/js/src/tab'
// import 'bootstrap/js/src/toast'
import 'bootstrap/js/src/tooltip'

// UI Components
import 'tom-select'

// Gems without NPM package
import '../javascripts/vendor/gems';

// Custom scripts from core
function requireAll(r) { r.keys().forEach(r); }
requireAll(require.context('../javascripts/modules', true, /\.(js|coffee)$/));

/**
 * Load stimulus controllers and component controllers
 */
import "controllers";

// Custom scripts from all wagons
import '../javascripts/wagons';
import '@hotwired/turbo-rails';

import { Application } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

const application = Application.start()
// application.debug = true
window.Stimulus   = application
window.Popover = Popover


/**
 * Images
 */
// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
const images = require.context('../images', true);
const imagePath = (name) => images(name, true);

/**
 * Action Text
 */
require("trix")
require("@rails/actiontext")
// prevent adding attachments via drag and drop
document.addEventListener('trix-file-accept', function(event) {
  if(event.target.parentNode.parentNode.classList.contains('no-attachments')) {
    event.preventDefault();
  }
});

