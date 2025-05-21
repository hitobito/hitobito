//  Copyright (c) 2025, Hitobito. This file is part of
//  hitobito and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/hitobito/hitobito.

// enable tooltip on page load
$(document).on('turbo:load', function() {
  $('[data-bs-toggle="tooltip"]').tooltip({ placement: 'right'});
});

// enable tooltip on turbo render (e.g. form submits)
window.addEventListener('turbo:render', function () {
  $('[data-bs-toggle="tooltip"]').tooltip({ placement: 'right'});
});

// enable tooltip on popover open event
document.addEventListener("shown.bs.popover", () => {
  $('[data-bs-toggle="tooltip"]').tooltip({ placement: 'right'});
});
