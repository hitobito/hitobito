// Copyright (c) 2025, Hitobito AG. This file is part of
// hitobito_sac_cas and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

/*
This controller is used to remove and hide options in the dropdown for selecting configurations
masks of filters
 */
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
   static targets = ["menu"];

  connect() {
    this.observer = new MutationObserver(this.checkIfEmpty.bind(this));
    if (this.hasMenuTarget) {
      this.observer.observe(this.menuTarget, { childList: true });
    }
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect();
    }
  }

  checkIfEmpty() {
    if (this.menuTarget.children.length === 0) {
      this.element.style.visibility = "hidden";
    } else {
      this.element.style.visibility = "visible";
    }
  }
}
