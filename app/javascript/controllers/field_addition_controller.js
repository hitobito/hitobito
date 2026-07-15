// Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "result"]

  sourceTargetConnected() { this.recalculate() }
  sourceTargetDisconnected() { this.recalculate() }

  recalculate() {
    const sum = this.sourceTargets
      .filter(element => element.closest(".fields")?.style.display !== "none")
      .reduce((acc, element) => acc + this.read(element), 0)
    this.resultTargets.forEach(
      element => this.write(element, sum.toFixed(2))
    )
    this.dispatch("recalculated")
  }

  read(element) {
    return parseFloat("value" in element ? element.value : element.textContent) || 0
  }

  write(element, value) {
    "value" in element ? element.value = value : element.textContent = value
  }
}
