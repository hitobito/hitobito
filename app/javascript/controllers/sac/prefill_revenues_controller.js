// Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import { Controller } from "@hotwired/stimulus"

// Currently (Jun '26) we are not able to import libraries using webpacker inside wagons.
// Therefore we place wagon stimulus controllers in core until webpacker is replaced.

export default class extends Controller {
  static values = { url: String }

  async prefill() {
    const response = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
    const rows = await response.json()

    const incomingDescriptions = new Set(rows.map(r => r.description))
    for (const el of this.element.querySelectorAll(".fields")) {
      if (el.style.display !== "none") {
        const descInput = el.querySelector("input[name*='[description]']")
        if (descInput && incomingDescriptions.has(descInput.value)) {
          this.removeRow(el)
        }
      }
    }

    rows.forEach(row => this.applyRow(row))
  }

  applyRow({ description, count, amount }) {
    if (count > 0) this.addRow(description, count, amount)
  }

  addRow(description, count, amount) {
    const nestedFormEl = this.element.querySelector("[data-controller*='nested-form']")
    const newRow = this.cloneTemplateRow(nestedFormEl)
    this.setInput(newRow, "[name*='[description]']", description)
    this.setInput(newRow, "[name*='[count]']", count)
    this.setInput(newRow, "[name*='[amount]']", amount)
  }

  removeRow(fieldsEl) {
    fieldsEl.style.display = "none"
    const destroyInput = fieldsEl.querySelector("input[name*='[_destroy]']")
    if (destroyInput) destroyInput.value = "1"
  }

  cloneTemplateRow(nestedFormEl) {
    const assoc = nestedFormEl.dataset.nestedFormAssocValue
    const placeholder = new RegExp(`NEW_${assoc.toUpperCase()}_RECORD`, "g")
    const target = nestedFormEl.querySelector("[data-nested-form-target='target']")
    const template = nestedFormEl.querySelector("template[data-nested-form-target='template']")
    target.insertAdjacentHTML("beforebegin", template.innerHTML.replace(placeholder, Date.now().toString()))
    return target.previousElementSibling
  }

  setInput(container, selector, value) {
    const el = container.querySelector(`input${selector}`)
    el.value = value
    el.dispatchEvent(new Event("input", { bubbles: true }))
  }
}
