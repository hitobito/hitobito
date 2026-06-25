// Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import { Controller } from "@hotwired/stimulus";

// Disables inputs inside hidden responsive containers before form submission so
// that only the visible layout's values are submitted (avoids duplicate field names
// being sent when Bootstrap responsive classes hide one of two sibling layouts).
export default class extends Controller {
  static targets = ["container"];

  submit() {
    this.containerTargets.forEach((container) => {
      const hidden = getComputedStyle(container).display === "none";
      container
        .querySelectorAll("input, select, textarea")
        .forEach((el) => (el.disabled = hidden));
    });
  }
}
