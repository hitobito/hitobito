// Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import { Controller } from "@hotwired/stimulus";

// Shows elements only when a master field has a specific value.
// All select and input fields inside are cleared when the element is hidden.
//
// Usage:
//   %div{ data: { controller: "conditional-visibility",
//                 "conditional-visibility-master-id-value": "person_country",
//                 "conditional-visibility-show-when-value": "CH" } }
//     = f.labeled_select(:canton, ...)

export default class extends Controller {
  static values = {
    masterId: String,
    showWhen: String,
  };

  connect() {
    this.masterField = document.getElementById(this.masterIdValue);
    if (!this.masterField) return;

    this.masterField.addEventListener("change", this.handleChange);
    this.updateVisibility(this.masterField.value);
  }

  disconnect() {
    this.masterField?.removeEventListener("change", this.handleChange);
  }

  handleChange = (event) => {
    this.updateVisibility(event.target.value);
  };

  updateVisibility(value) {
    if (value === this.showWhenValue) {
      this.element.classList.remove("hidden");
    } else {
      this.element.classList.add("hidden");
      this.clearFields();
    }
  }

  clearFields() {
    this.clearSelectFields();
    this.clearInputFields();
  }

  clearSelectFields() {
    this.element.querySelectorAll("select").forEach((select) => {
      if (select.tomselect) {
        select.tomselect.clear();
      } else {
        select.value = "";
      }
    });
  }

  clearInputFields() {
    this.element.querySelectorAll("input:not([type=hidden])").forEach((input) => {
      if (input.type === "checkbox") {
        input.checked = false;
      } else {
        input.value = "";
      }
    });
  }
}
