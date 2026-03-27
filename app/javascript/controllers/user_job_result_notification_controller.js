// Copyright (c) 2026, Hitobito AG. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito.

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    const toast = new Toast(this.element)
    toast.show()
  }
}
