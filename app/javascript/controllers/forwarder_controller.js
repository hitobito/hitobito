// Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
// hitobito_sac_cas and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "click" ]

  click() {
    this.clickTargets.forEach(target => target.click())
  }
}
