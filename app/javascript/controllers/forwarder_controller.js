// Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
// hitobito_sac_cas and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import { Controller } from "@hotwired/stimulus";
import debounce from "lodash.debounce";

export default class extends Controller {
  static targets = ["click"];
  static values = {
    delay: {
      type: Number,
      default: 0,
    },
  };

  initialize() {
    this.click = this.click.bind(this);
  }

  connect() {
    if (this.delayValue > 0) {
      this.click = debounce(this.click, this.delayValue);
    }
  }

  click() {
    this.clickTargets.forEach((target) => target.click());
  }
}
