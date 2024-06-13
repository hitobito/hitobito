/* eslint no-console:0 */

/**
 * Copyright (c) 2020, hitobito AG. This file is part of
 * hitobito and licensed under the Affero General Public License version 3
 * or later. See the COPYING file at the top-level directory or at
 * https://github.com/hitobito/hitobito.
 */

/**
 * Dependencies
 */
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
import './dynamic/gems';

// Custom scripts from core
// import './modules/ajax_error_notification.js.coffee';
// import './modules/ajax_replace.js.coffee';
// import './modules/ajax_upload.js.coffee';
// import './modules/async_downloads.js.coffee';
// import './modules/async_synchronizations.js.coffee';
// import './modules/auto_submit.js.coffee';
// import './modules/checkable.js.coffee';
// import './modules/clear_input.js.coffee';
// import './modules/clickable_placeholders.js.coffee';
// import './modules/collapse_overflow_fix.js.coffee';
// import './modules/copy_to_clipboard.js.coffee';
// import './modules/datepicker.js.coffee';
// import './modules/disabled_links.js.coffee';
// import './modules/element_swapper.js.coffee';
// import './modules/element_toggler.js.coffee';
// import './modules/event_kind_preconditions.js.coffee';
// import './modules/fields_autofocus.js.coffee';
// import './modules/help_texts.js.coffee';
// import './modules/input_enabler.js.coffee';
// import './modules/invoice_articles.js.coffee';
// import './modules/invoices.js.coffee';
// import './modules/mailing_list_labels.js.coffee';
// import './modules/multiselect_add_chips.js.coffee';
// import './modules/multiselect.js.coffee';
// import './modules/nav_off_canvas.js.coffee';
// import './modules/nested_fields.js.coffee';
// import './modules/notes.js.coffee';
// import './modules/on_page_load.js.coffee';
// import './modules/participation_lists.js.coffee';
// import './modules/persistent_dropdown.js.coffee';
import './modules/popover_handler.js';
// import './modules/profile_overlay.coffee';
import './modules/remote_autocomplete.js';
// import './modules/spinner.js.coffee';
// import './modules/string_trim.js.coffee';
// import './modules/subscriber_lists.js.coffee';
import './modules/tom_select.js';
import './modules/tooltips.js';
import './modules/contactables/contactable_address_field.js';
// import './modules/events/application_market.js.coffee';
// import './modules/events/date_period_validator.js.coffee';
// import './modules/events/events.js.coffee';
// import './modules/events/event_tags.js.coffee';
// import './modules/groups/group_contact_toggle.js.coffee';
// import './modules/people/households.js.coffee';
// import './modules/people/people_filter_attribute.js.coffee';
// import './modules/people/people_filter_qualification_validity_toggle.js.coffee';
// import './modules/people/people_filter_role_toggle.js.coffee';
// import './modules/people/person_tags.js.coffee';
import './modules/people/toggle_household_for_labels.js';

/**
 * Load stimulus controllers and component controllers
 */
import "./controllers";

// Custom scripts from all wagons
import './dynamic/wagons';
import '@hotwired/turbo-rails';

import { Application } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

const application = Application.start()
// application.debug = true
window.Stimulus   = application
window.Popover = Popover


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
