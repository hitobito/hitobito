// Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
// hitobito_sac_cas and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["toggle", "toggleOpposite"];

  static values = {
    hideOn: { type: Array, default: [""] },
  }

  toggle(event) {
    if(event.target.tagName === "SELECT") {
      const selected = event.target.options[event.target.options.selectedIndex];

      if (selected.dataset.visibility === "true") {
        this.revealToggleTarget();
      } else {
        this.hideToggleTarget();
      }
    } else if (event.target.tagName === "INPUT") {
      if(this.#hideOnConfigured()) {
        if (!this.hideOnValue.includes(event.target.value)) {
          this.revealToggleTarget();
        } else {
          this.hideToggleTarget();
        }
      } else {
        this.toggleTarget.classList.toggle("hidden");
        if(this.hasToggleOppositeTarget) { this.toggleOppositeTarget.classList.toggle("hidden") }
      }
    } else {
      this.revealToggleTarget();
    }
  }

  untoggle() {
    this.hideToggleTarget();
  }

  revealToggleTarget() {
    this.toggleTarget.classList.remove("hidden");
    if(this.hasToggleOppositeTarget) { this.toggleOppositeTarget.classList.add("hidden") }
  }

  hideToggleTarget() {
    this.toggleTarget.classList.add("hidden");
    if(this.hasToggleOppositeTarget) { this.toggleOppositeTarget.classList.remove("hidden") }
  }

  #hideOnConfigured() {
    return !(this.hideOnValue.length == 1 && this.hideOnValue.includes(""));
  }
}
