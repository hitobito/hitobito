// Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
// hitobito_sac_cas and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

/* This controller is used to hide the date configuration options if the
* user selects active_today as validity inside for the role inside the people filter options */

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "date"];

  toggleDate() {
    const isActiveToday = this.selectTarget.value === "active_today"
    isActiveToday ? this.dateTarget.classList.add("d-none") : this.dateTarget.classList.remove("d-none")
  }
}
