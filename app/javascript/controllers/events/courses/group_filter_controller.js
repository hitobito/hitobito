//  Copyright (c) 2012-2025, Jungwacht Blauring Schweiz. This file is part of
//  hitobito and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/hitobito/hitobito.

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static outlets = ["tom-select"];

  add({ params: { id } }) {
    this.tomSelectOutlet.tom.addItem(id, true);
  }

  clear(event) {
    this.tomSelectOutlet.tom.clear(true);
  }
}
