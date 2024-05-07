// Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
// hitobito_sac_cas and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["toggle"];

  toggle(event) {
    const selected = event.target.options[event.target.options.selectedIndex];

    if (selected.dataset.visibility === "true") {
      this.toggleTarget.classList.remove("hidden");
    } else {
      this.toggleTarget.classList.add("hidden");
    }
  }
}
