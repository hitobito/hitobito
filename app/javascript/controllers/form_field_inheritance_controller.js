// Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

/**
 * Handles form field inheritance from predefined value sets.
 *
 * This controller allows users to inherit multiple form field values from a selected
 * option in a datalist. Each option in the datalist contains data attributes that
 * specify which target fields to populate and what values to use.
 *
 * When a user selects an option to inherit from, the controller populates all
 * associated form fields with the predefined values. Users can then override
 * individual fields while preserving their custom values (as long as they differ
 * from the defaults).
 *
 * The controller expects:
 * - A datalist with options containing data-source-id, data-target-field, data-value,
 *   and data-default attributes
 * - Form fields with IDs matching the data-target-field values
 *
 * Usage:
 *   <div data-controller="form-field-inheritance">
 *     <select data-action="change->form-field-inheritance#inherit">
 *       <option value="template1">Template 1</option>
 *     </select>
 *     <datalist>
 *       <option data-source-id="template1" data-target-field="field1" data-value="foo" data-default="bar">
 *     </datalist>
 *     <input id="field1">
 *   </div>
 */
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {

  inherit(event) {
    this.#setValues(event.target.value, true)
  }

  override(event) {
    event.preventDefault();
    const value = event.target.closest('.labeled').querySelector('select').value
    this.#setValues(value, false)
  }

  #setValues(value, keep) {
    const options = this.#getDatalistOptions(value);
    Array.from(options).forEach((option) => this.#setValue(option, keep))
  }

  #setValue(option, keep) {
    const input = this.#getForm().querySelector(`#${option.dataset.targetField}`)
    const value = option.dataset.value;

    if(keep && this.#keep(input, option.dataset.default)) {
      return;
    }

    if(input.type == 'checkbox') {
      input.checked = (/true/).test(value)
    } else {
      input.value = value;
      input.dispatchEvent(new Event('input'));
    }
  }

  #keep(input, defaultValue) {
    if(input.type == 'checkbox') {
      return input.checked != (/true/).test(defaultValue);
    } else {
      return input.value.length > 0 && input.value != defaultValue;
    }
  }

  #getDatalistOptions(id) {
    const selector = `datalist > option[data-source-id="${id}"]`;
    return this.#getForm().querySelectorAll(selector)
  }

  #getForm() {
    return this.element.closest('form')
  }
}
