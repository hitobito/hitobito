// Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

/**
 * Toggles visibility of form fields based on user input.
 *
 * This controller dynamically shows or hides form elements (toggle target and
 * optionally toggleOpposite target) based on the state of another form field.
 * It supports multiple toggle strategies:
 *
 * - Select elements: Toggles based on the selected option's data-visibility attribute
 *   ("true" to show, anything else to hide)
 *
 * - Input elements with hideOn value: Hides the target when the input value matches
 *   any value in the hideOn array
 *
 * - Input elements with hideOnBlank: Hides the target when the input is empty,
 *   shows it when it has a value
 *
 * - Default toggle: Simple show/hide toggle for other input types
 *
 * The toggleOpposite target provides inverse visibility (when toggle is shown,
 * toggleOpposite is hidden, and vice versa).
 *
 * Usage:
 *   <div data-controller="form-field-toggle"
 *        data-form-field-toggle-hide-on-value="["hidden_value"]"
 *        data-form-field-toggle-hide-on-blank-value="true">
 *     <input data-action="input->form-field-toggle#toggle">
 *     <div data-form-field-toggle-target="toggle">Conditional content</div>
 *     <div data-form-field-toggle-target="toggleOpposite">Inverse content</div>
 *   </div>
 */
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["toggle", "toggleOpposite"];

  static values = {
    hideOn: { type: Array, default: [""] },
    hideOnBlank: { type: Boolean, default: false },
  }

  toggle(event) {
    if(event.target.tagName === "SELECT") {
      const selected = event.target.options[event.target.options.selectedIndex];

      if (selected.dataset.visibility === "true") {
        this.revealToggleTarget();
      } else {
        this.hideToggleTarget();
      }
    } else if (event.target.tagName === "INPUT") {
      if(this.#hideOnConfigured()) {
        if (!this.hideOnValue.includes(event.target.value)) {
          this.revealToggleTarget();
        } else {
          this.hideToggleTarget();
        }
      } else if (this.hideOnBlankValue) {
        if (!!event.target.value) {
          this.revealToggleTarget();
        } else {
          this.hideToggleTarget();
        }
      } else {
        this.toggleTarget.classList.toggle("hidden");
        if(this.hasToggleOppositeTarget) { this.toggleOppositeTarget.classList.toggle("hidden") }
      }
    } else {
      this.revealToggleTarget();
    }
  }

  untoggle() {
    this.hideToggleTarget();
  }

  revealToggleTarget() {
    this.toggleTarget.classList.remove("hidden");
    if(this.hasToggleOppositeTarget) { this.toggleOppositeTarget.classList.add("hidden") }
  }

  hideToggleTarget() {
    this.toggleTarget.classList.add("hidden");
    if(this.hasToggleOppositeTarget) { this.toggleOppositeTarget.classList.remove("hidden") }
  }

  #hideOnConfigured() {
    return !(this.hideOnValue.length == 1 && this.hideOnValue.includes(""));
  }
}
