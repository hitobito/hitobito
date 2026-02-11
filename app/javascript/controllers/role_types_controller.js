// Copyright (c) 2026, BdP and DPSG. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import {Controller} from '@hotwired/stimulus';

export default class extends Controller {
  static targets = [ "modal", "summary", "checkbox" ]

  get modalTarget() {
    if (this._modalTarget) return this._modalTarget
    return this.element.querySelector("[data-role-types-target=modal]")
  }

  get checkboxTargets() {
    return Array.from(this.modalTarget.querySelectorAll("[data-role-types-target=checkbox]"))
  }

  connect() {
    this.modalTarget.addEventListener("hide.bs.modal", () => this.#updateSummary())
    this.#updateSummary()
  }

  disconnect() {
    this.modalTarget.removeEventListener("hide.bs.modal", () => this.#updateSummary())
  }

  #updateSummary() {
    this.summaryTarget.innerText = this.checkboxTargets
      .filter(checkbox => checkbox.checked)
      .map((checkbox) => checkbox.dataset.roleTypesLabel)
      .join(", ")
  }
}
