// Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
// hitobito_sac_cas and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito
//
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["main", "dependent"];
  static values = {
    selectDependentCheckboxes: { type: Boolean, default: false },
    uncheckDependentOnMainToggle: { type: Boolean, default: false }
  }

  // unselects all dependent checkboxes when checking/unchecking master checkbox
  toggleMain() {
    if (!event.target.checked || (this.uncheckDependentOnMainToggleValue && event.target.checked)) {
      this.dependentTargets.forEach((checkbox) => {
        checkbox.checked = false;
      });
    } else if (this.selectDependentCheckboxesValue) {
      this.dependentTargets.forEach((checkbox) => {
        checkbox.checked = true;
      });
    }
  }

  // selects or unselects master checkbox if any dependent checkbox is checked
  toggleDependent() {
    this.mainTarget.checked = !this.uncheckDependentOnMainToggleValue;
  }
}
