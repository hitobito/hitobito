// Copyright (c) 2026, Puzzle ITC. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["submitButton"];

  static values = {
    expected: String,
  };

  validate(event) {
    if (!this.hasSubmitButtonTarget) return;

    const isValid =
      event.target.value.toLowerCase().trim() === this.expectedValue.toLowerCase();

    this.submitButtonTarget.disabled = !isValid;
    this.submitButtonTarget.classList.toggle("disabled", !isValid);
    this.submitButtonTarget.setAttribute("aria-disabled", (!isValid).toString());
    this.submitButtonTarget.tabIndex = isValid ? 0 : -1;
  }
}
