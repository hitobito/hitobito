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

  add(event) {
    if (this.#getVisibleFieldsCount() >= this.limitValue) {
      return
    }
    super.add(event)
    this.#setFocusOnFirstFieldInLastWrapper()
    this.#handleAddButtonVisibility()
    this.#activateTooltipsInNewInputs()
  }

  remove(event) {
    super.remove(event)
    this.#handleAddButtonVisibility()
    this.#removeRequiredAttributeFromRemovedInputs(event.target)
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

  #activateTooltipsInNewInputs() {
    // The eventListener for this event is in tooltips.js.
    document.dispatchEvent(new CustomEvent("activateTooltips"));
  }

  #removeRequiredAttributeFromRemovedInputs(wrapper) {
    wrapper.querySelectorAll('[required]').forEach(el => {
      el.removeAttribute('required');
    });
  }
}
