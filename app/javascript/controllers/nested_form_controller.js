// Copyright (c) 2026, BdP and DPSG. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import NestedForm from "@stimulus-components/rails-nested-form/dist/stimulus-rails-nested-form.umd.js"

export default class extends NestedForm {
  static values = {
    assoc: String,
    limit: { type: Number, default: Number.POSITIVE_INFINITY },
  }

  get wrapperSelectorValue() {
    return `#${this.assocValue}_fields .fields`
  }

  connect() {
    this.#handleAddButtonVisibility()
  }

  add(e) {
    this.insertTemplate(this.templateTarget)
  }

  insertTemplate(templateTarget) {
    if (this.#getVisibleFieldsCount() >= this.limitValue) {
      return
    }

    // Generate a unique ID using timestamp (integer as string)
    // Rails strong parameters automatically permit integer-like strings for nested attributes
    const uniqueId = new Date().getTime().toString()

    const placeholder = `NEW_${this.assocValue.toUpperCase()}_RECORD`
    const content = templateTarget.innerHTML.replace(new RegExp(placeholder, 'g'), uniqueId)

    // Insert the new fields
    this.targetTarget.insertAdjacentHTML("beforebegin", content)

    const event = new CustomEvent("rails-nested-form:add", { bubbles: true })
    this.element.dispatchEvent(event)

    this.#setFocusOnFirstFieldInLastWrapper()
    this.#handleAddButtonVisibility()
  }

  remove(event) {
    this.#removeEntry(event)

    this.dispatch("remove")
    this.#handleAddButtonVisibility()
    this.#removeRequiredAttributeFromRemovedInputs(event.target)
  }

  // Copied from the parent's (rails-nested-form) remove() because we cannot
  // just call super: it sets _destroy=1 on the first "input[name*='_destroy']"
  // found inside the wrapper. When a wrapper contains nested form fields
  // itself (e.g. an event question with choices), that input belongs to a
  // nested entry and the wrapper's own _destroy stays unset, so the record is
  // never destroyed.
  // See https://github.com/hitobito/hitobito/issues/4514
  #removeEntry(event) {
    event.preventDefault()

    const wrapper = event.target.closest(this.wrapperSelectorValue)
    if (!wrapper) return

    if (wrapper.dataset.newRecord === "true") {
      wrapper.remove()
    } else {
      wrapper.style.display = "none"
      const input = this.#findOwnDestroyInput(wrapper)
      if (input) input.value = "1"
    }

    const removeEvent = new CustomEvent("rails-nested-form:remove", { bubbles: true })
    this.element.dispatchEvent(removeEvent)
  }

  // Finds the wrapper's own _destroy input. Wrappers may contain nested
  // forms (e.g. event question choices) which carry their own _destroy
  // inputs, so a plain querySelector would hit the wrong one.
  #findOwnDestroyInput(wrapper) {
    return Array.from(wrapper.querySelectorAll("input[name*='_destroy']"))
      .find((el) => el.closest(this.wrapperSelectorValue) === wrapper)
  }

  #setFocusOnFirstFieldInLastWrapper() {
    const wrappers = this.element.querySelectorAll(this.wrapperSelectorValue)
    if (!wrappers.length) return
    wrappers[wrappers.length - 1].querySelector('input')?.focus()
  }

  #getVisibleFieldsCount() {
    return Array.from(this.element.querySelectorAll(`#${this.assocValue}_fields .fields`))
      .filter(el => getComputedStyle(el).display !== "none")
      .length
  }

  #handleAddButtonVisibility() {
    const addButton = this.element.querySelector("[data-action=\"nested-form#add\"]")
    if (!addButton) return

    const currentCount = this.#getVisibleFieldsCount()
    if (currentCount >= this.limitValue) {
      addButton.classList.add("hidden")
    } else {
      addButton.classList.remove("hidden")
    }
  }

  #removeRequiredAttributeFromRemovedInputs(wrapper) {
    wrapper.querySelectorAll('[required]').forEach(el => {
      el.removeAttribute('required');
    });
  }
}
