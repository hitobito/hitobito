// Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
// hitobito_sac_cas and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["toggle"];

  static values = {
    hideOn: { type: Array, default: [""] },
  }

  toggle(event) {
    if(event.target.tagName === "SELECT") {
      const selected = event.target.options[event.target.options.selectedIndex];

      if (selected.dataset.visibility === "true") {
        this.toggleTarget.classList.remove("hidden");
      } else {
        this.toggleTarget.classList.add("hidden");
      }
    } else if (event.target.tagName === "INPUT") {
      if(this.#hideOnConfigured()) {
        if (!this.hideOnValue.includes(event.target.value)) {
          this.toggleTarget.classList.remove("hidden");
        } else {
          this.toggleTarget.classList.add("hidden");
        }
      } else {
        this.toggleTarget.classList.toggle("hidden");
      }
    } else {
      this.toggleTarget.classList.toggle("hidden");
    }
  }

  untoggle() {
    this.toggleTarget.classList.add("hidden");
  }

  #hideOnConfigured() {
    return !(this.hideOnValue.length == 1 && this.hideOnValue.includes(""));
  }
}
