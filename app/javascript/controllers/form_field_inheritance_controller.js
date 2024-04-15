// Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

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
