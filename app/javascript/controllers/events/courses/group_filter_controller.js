//  Copyright (c) 2012-2025, Jungwacht Blauring Schweiz. This file is part of
//  hitobito and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/hitobito/hitobito.

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static outlets = ["tom-select"];
  static targets = [ "chip", "clear" ];

  add({ params: { id } }) {
    this.tomSelectOutlet.tom.addItem(id, true);
    this.change();
  }

  clear(event) {
    this.tomSelectOutlet.tom.clear(true);
    this.change();
  }

  change() {
    let selected = this.tomSelectOutlet.tom.getValue();
    this.chipTargets.forEach(chip => {
      chip.style.display = 'none';
      let id = chip.dataset["events-Courses-GroupFilterIdParam"];
      if (!selected.includes(id)) chip.style.display = 'inline';
    })
    if (selected.length > 0) {
      this.clearTarget.style.display = 'inline';
    } else {
      this.clearTarget.style.display = 'none';
    }
  }

  connect() {
    this.change();
  }
}
