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

    const unchangedRows = new Set()
    this.visibleFieldsElements.forEach(fieldsElement => {
      const matchingRow = rows.find(row => row.count > 0 && this.matchesRow(fieldsElement, row))
      if (matchingRow) {
        unchangedRows.add(matchingRow)
      } else if (rows.some(({ description }) => description === this.inputValue(fieldsElement, "[description]"))) {
        this.removeRow(fieldsElement)
      }
    })

    const nestedFormElement = this.element.querySelector("[data-controller*='nested-form']")
    rows
      .filter(row => row.count > 0 && !unchangedRows.has(row))
      .forEach(row => this.addRow(nestedFormElement, row))
  }

  matchesRow(fieldsElement, { description, count, amount }) {
    return this.inputValue(fieldsElement, "[description]") === description &&
      Number(this.inputValue(fieldsElement, "[count]")) === Number(count) &&
      Number(this.inputValue(fieldsElement, "[amount]")) === Number(amount)
  }

  inputValue(fieldsElement, selector) {
    return fieldsElement.querySelector(`input[name*='${selector}']`)?.value
  }

  get visibleFieldsElements() {
    return [...this.element.querySelectorAll(".fields")].filter(fieldsElement => fieldsElement.style.display !== "none")
  }

  addRow(nestedFormElement, { description, count, amount }) {
    const newRowElement = this.cloneTemplateRow(nestedFormElement)
    this.setInputs(newRowElement, { "[description]": description, "[count]": count, "[amount]": amount })
  }

  removeRow(fieldsElement) {
    fieldsElement.style.display = "none"
    const destroyInput = fieldsElement.querySelector("input[name*='[_destroy]']")
    if (destroyInput) destroyInput.value = "1"
  }

  cloneTemplateRow(nestedFormElement) {
    const assoc = nestedFormElement.dataset.nestedFormAssocValue
    const placeholder = new RegExp(`NEW_${assoc.toUpperCase()}_RECORD`, "g")
    const targetElement = nestedFormElement.querySelector("[data-nested-form-target='target']")
    const templateElement = nestedFormElement.querySelector("template[data-nested-form-target='template']")
    targetElement.insertAdjacentHTML("beforebegin", templateElement.innerHTML.replace(placeholder, this.nextUniqueId()))
    return targetElement.previousElementSibling
  }

  nextUniqueId() {
    this.uniqueIdSeq = (this.uniqueIdSeq ?? Date.now()) + 1
    return this.uniqueIdSeq.toString()
  }

  setInputs(containerElement, valuesBySelector) {
    for (const [selector, value] of Object.entries(valuesBySelector)) {
      const inputElement = containerElement.querySelector(`input[name*='${selector}']`)
      inputElement.value = value
      inputElement.dispatchEvent(new Event("input", { bubbles: true }))
    }
  }
}
