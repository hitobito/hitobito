//  Copyright (c) 2025, Hitobito This file is part of
//  hitobito and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/hitobito/hitobito.

import * as bootstrap from 'bootstrap'

function registerTooltips() {
  const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
  tooltipTriggerList.forEach(el => {
    new bootstrap.Tooltip(el)
  })
}

document.addEventListener('DOMContentLoaded', registerTooltips);
// enable tooltip on turbo render (e.g. form submits)
document.addEventListener('turbo:render', registerTooltips);
// enable tooltip on popover open event
document.addEventListener("shown.bs.popover", registerTooltips);
