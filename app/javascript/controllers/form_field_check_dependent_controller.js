// Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

/**
 * Manages checkbox relationships between a main checkbox and dependent checkboxes.
 *
 * This controller coordinates the interaction between a primary checkbox (main target)
 * and one or more dependent checkboxes (dependent targets). It supports two interaction modes:
 *
 * - "default": When the main checkbox is unchecked, all dependents are unchecked.
 *   When a dependent is checked, the main checkbox is automatically checked. If
 *   selectDependentCheckboxes is true, checking the main checkbox also checks all dependents.
 *
 * - "exclusive": When the main checkbox is checked, all dependents are unchecked.
 *   When a dependent is checked, the main checkbox is unchecked. This ensures only one
 *   option can be selected at a time.
 *
 * Usage:
 *   <div data-controller="form-field-check-dependent"
 *        data-form-field-check-dependent-interaction-mode-value="exclusive"
 *        data-form-field-check-dependent-select-dependent-checkboxes-value="true">
 *     <input type="checkbox" data-form-field-check-dependent-target="main"
 *            data-action="form-field-check-dependent#toggleMain">
 *     <input type="checkbox" data-form-field-check-dependent-target="dependent"
 *            data-action="form-field-check-dependent#toggleDependent">
 *   </div>
 */
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["main", "dependent"];
  static values = {
    interactionMode: { type: String, default: "default" },
    selectDependentCheckboxes: { type: Boolean, default: false }
  }

  toggleMain(event) {
    const isChecked = event.target.checked;

    if (this.interactionModeValue === "exclusive") {
      if (isChecked) {
        this.dependentTargets.forEach(cb => cb.checked = false);
      }
    } else {
      if (!isChecked) {
        this.dependentTargets.forEach(cb => cb.checked = false);
      } else if (this.selectDependentCheckboxesValue) {
        this.dependentTargets.forEach(cb => cb.checked = true);
      }
    }
  }

  toggleDependent(event) {
    const isChecked = event.target.checked;

    if (this.interactionModeValue === "exclusive") {
      if (isChecked && this.hasMainTarget) {
        this.mainTarget.checked = false;
      }
    } else {
      if (this.hasMainTarget) {
        this.mainTarget.checked = true;
      }
    }
  }
}
