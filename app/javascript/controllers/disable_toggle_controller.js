// Copyright (c) 2024-2026, Schweizer Alpen-Club. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["toggled", "inverted"];

  toggle(event) {
    const togglers = this.element.querySelectorAll(
      "[data-action='disable-toggle#toggle']",
    );
    const allChecked = Array.from(togglers).every((cb) => cb.checked === true);

    this.toggledTargets.forEach((target) => (target.disabled = !allChecked));
    this.invertedTargets.forEach((target) => (target.disabled = allChecked));
  }
}
