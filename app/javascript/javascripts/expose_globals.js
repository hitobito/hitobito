// Copyright (c) 2026, hitobito AG. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito.

// A lot of legacy CoffeeScript modules (core and wagons) reference jQuery
// and moment as globals rather than importing them. This must be the
// first import in packs/core.js so these globals exist before anything
// else (jquery-ujs, jquery-ui, core/wagon modules) is evaluated.
import jQuery from 'jquery';
import moment from 'moment'; // used by events/date_period_validator.js.coffee

window.jQuery = window.$ = jQuery;
window.moment = moment;
