// Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

/**
 * Shows or hides a container target based on another field's value.
 *
 * Values:
 *   dependentId: ID of the field to watch for changes
 *   showWhen: Value to check for to show the container (Can be used for inputs, selects or checkboxes)
 *   showWhenPresent: Show whenever the field has any non-empty value
 *   showWhenData: Read a data attribute from the triggering element and show when it is true
 *   clearInputs: Clears the values of the inputs when container is hidden
 *
 */

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["container"];

  static values = {
    dependentId: String,
    showWhen: String,
    showWhenPresent: { type: Boolean, default: false },
    showWhenData: String,
    clearInputs: { type: Boolean, default: false },
  };

  connect() {
    this.dependent = document.getElementById(this.dependentIdValue);
    if (!this.dependent) return;

    this.dependent.addEventListener("change", this.handleChange);
  }

  disconnect() {
    this.dependent?.removeEventListener("change", this.handleChange);
  }

  handleChange = (event) => {
    const element = event.target;
    let visible;

    if (this.showWhenDataValue) {
      const source = element.tagName === "SELECT" ? element.options[element.selectedIndex] : element;
      visible = source?.dataset[this.showWhenDataValue] === "true";
    } else {
      const value = element.type === "checkbox" ? (element.checked ? element.value : "") : element.value;
      visible = this.showWhenPresentValue ? !!value : value === this.showWhenValue;
    }

    visible ? this.show() : this.hide();
  };

  show() {
    this.containerTarget.classList.remove("hidden");
  }

  hide() {
    this.containerTarget.classList.add("hidden");
    if (this.clearInputsValue) this.clear();
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
