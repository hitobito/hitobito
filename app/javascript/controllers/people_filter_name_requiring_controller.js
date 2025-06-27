// Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
// hitobito_sac_cas and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import { Controller } from "@hotwired/stimulus"

// This controller is used to change the filter submit button to either
// search or save the filter

export default class extends Controller {
  static targets = ["filter", "label"];

  changeRequired() {
    const isRequired = this.filterTarget.value === "save"
    this.labelTarget.classList.toggle("required", !isRequired);
    this.filterTarget.value = isRequired ? "search" : "save"
  }
}
