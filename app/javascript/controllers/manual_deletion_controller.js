//  Copyright (c) 2012-2025, Jungwacht Blauring Schweiz. This file is part of
//  hitobito and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/hitobito/hitobito.

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["toggle", "deleteButton", "minimizeButton"];

  connect() {
    // Store initial disabled state of each button
    this.initialDeleteButtonState = this.deleteButtonTarget.disabled;
    this.initialMinimizeButtonState = this.minimizeButtonTarget.disabled;

    this.updateButtons();
  }

  toggle() {
    this.updateButtons();
  }

  updateButtons() {
    if (this.toggleTarget.checked) {
      // Enable both buttons when checked
      this.deleteButtonTarget.disabled = false;
      this.minimizeButtonTarget.disabled = false;
    } else {
      // Restore original disabled state when unchecked
      this.deleteButtonTarget.disabled = this.initialDeleteButtonState;
      this.minimizeButtonTarget.disabled = this.initialMinimizeButtonState;
    }
  }
}
