// Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
// hitobito_sac_cas and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito
//
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["checkbox"]

  // unselects all dependent checkboxes when unchecking master checkbox
  handleMasterCheckbox() {
    const dependentCheckboxes = this.element.querySelectorAll('[data-action="form-field-check-dependent#handleDependentCheckbox"]');

    if(!event.target.checked) {
      dependentCheckboxes.forEach((checkbox) => {
        checkbox.checked = false;
      });
    }
  }

  // selects master checkbox if any dependent checkbox is checked
  handleDependentCheckbox() {    
    const dependentCheckboxes = this.element.querySelectorAll('[data-action="form-field-check-dependent#handleDependentCheckbox"]');

    const isAnyChecked = Array.from(dependentCheckboxes).some(checkbox => checkbox.checked);

    if (isAnyChecked) {
      this.checkboxTarget.checked = true;
    } else {
      this.checkboxTarget.checked = false;
    }
  }
}