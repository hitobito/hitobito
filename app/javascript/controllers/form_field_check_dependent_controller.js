// Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
// hitobito_sac_cas and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito
//
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["main", "dependent"]

  // unselects all dependent checkboxes when unchecking master checkbox
  toggleMainCheckbox() {
    if(!event.target.checked) {
      this.dependentTargets.forEach((checkbox) => {
        checkbox.checked = false;
      });
    }
  }

  // selects master checkbox if any dependent checkbox is checked
  toggleDependentCheckbox() {    
    this.mainTarget.checked = true;
  }
}