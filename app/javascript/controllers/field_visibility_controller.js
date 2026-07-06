// Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

/**
 * Shows or hides a container target based on another field's value.
 *
 * Values:
 *   observedFieldId: ID of the field to watch for changes
 *   showWhen: Value to check for to show the container (Can be used for inputs, selects or checkboxes)
 *   showWhenPresent: Show whenever the field has any non-empty value
 *   showWhenData: Read a data attribute from the triggering element and show when it is true
 *   hideWhen: Value to check for to hide the container
 *   hideWhenPresent: Hide whenever the field has any non-empty value
 *   hideWhenData: Read a data attribute from the triggering element and hide when it is true
 *   clearContainerInputsOnHide: Clears the values of the inputs when container is hidden
 *
 */

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["container"];

  static values = {
    observedFieldId: String,
    showWhen: String,
    showWhenPresent: { type: Boolean, default: false },
    showWhenData: String,
    hideWhen: String,
    hideWhenPresent: { type: Boolean, default: false },
    hideWhenData: String,
    clearContainerInputsOnHide: { type: Boolean, default: false },
  };

  connect() {
    this.dependent = document.getElementById(this.observedFieldIdValue);
    if (!this.dependent) return;

    this.dependent.addEventListener("change", this.handleChange);
  }

  disconnect() {
    this.dependent?.removeEventListener("change", this.handleChange);
  }

  handleChange = (event) => {
    const element = event.target;
    const dataCondition = this.showWhenDataValue || this.hideWhenDataValue;
    const shouldHide = !!(this.hideWhenDataValue || this.hideWhenPresentValue || this.hideWhenValue);

    let conditionMet;
    if (dataCondition) {
      const source = element.tagName === "SELECT" ? element.options[element.selectedIndex] : element;
      conditionMet = source?.dataset[dataCondition] === "true";
    } else {
      const value = element.type === "checkbox" ? (element.checked ? element.value : "") : element.value;
      conditionMet = this.showWhenPresentValue || this.hideWhenPresentValue ? !!value : value === (this.showWhenValue || this.hideWhenValue);
    }

    (shouldHide ? !conditionMet : conditionMet) ? this.show() : this.hide();
  };

  show() {
    this.containerTarget.classList.remove("hidden");
  }

  hide() {
    this.containerTarget.classList.add("hidden");
    if (this.clearContainerInputsOnHideValue) this.clear();
  }

  clear() {
    this.containerTarget.querySelectorAll("select").forEach((select) => {
      select.tomselect ? select.tomselect.clear() : (select.value = "");
    });

    this.containerTarget.querySelectorAll("input:not([type=hidden])").forEach((input) => {
      if (input.type === "checkbox" || input.type === "radio") {
        input.checked = false;
      } else {
        input.value = "";
      }
    });
  }
}
