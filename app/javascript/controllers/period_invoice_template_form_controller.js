// Copyright (c) 2026, BdP and DPSG. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import NestedForm from "./nested_form_controller"

export default class extends NestedForm {
  connect() {
    this.itemClass = null
  }

  add(event) {
    const prev = this.itemClass
    this.itemClass = event.params.itemClass

    super.add(event)

    this.itemClass = prev
  }

  get templateTarget() {
    const selector = `[data-period-invoice-template-form-item-type="${this.itemClass}"]`
    return this.templateTargets.find(target => target.matches(selector))
  }
}
