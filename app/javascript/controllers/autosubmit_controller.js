// Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
// hitobito_sac_cas and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import { Controller } from "@hotwired/stimulus"
import debounce from "lodash.debounce"

export default class extends Controller {
  static values = {
    delay: {
      type: Number,
      default: 150
    }
  }

  initialize() {
    this.save = this.save.bind(this)
  }

  connect() {
    if (this.delayValue > 0) {
      this.save = debounce(this.save, this.delayValue)
    }
  }

  save(event) {
    const submit = document.querySelector('input[name=autosubmit]')
    submit.value = event.target.name || "autosubmit";
    this.element.requestSubmit();
    submit.value = '';
  }
}
