// Copyright (c) 2026, hitobito AG. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito.

import { Controller } from "@hotwired/stimulus"

// Replaces the remotipart gem: jquery-ujs's `data-remote` can't submit real
// multipart/form-data over XHR, so remotipart used a hidden-iframe workaround.
// fetch()+FormData needs none - the response is still evaluated as JS, like
// jquery-ujs does for any .js-responding `data-remote` form.
export default class extends Controller {
  upload() {
    const form = this.element
    const body = new FormData(form)
    form.reset()

    // file_field(multiple: true) renders a hidden same-named input before the
    // real one, so FormData(form) picks up its empty string as a spurious
    // entry ahead of any chosen files under the same key - drop those.
    for (const name of new Set(body.keys())) {
      const files = body.getAll(name).filter((value) => value !== "")
      if (files.length) {
        body.delete(name)
        files.forEach((file) => body.append(name, file))
      }
    }

    $(form).trigger("ajax:beforeSend")

    fetch(form.action, {
      method: form.method,
      body,
      headers: {
        Accept: "text/javascript",
        "X-Requested-With": "XMLHttpRequest"
      }
    })
      .then((response) => response.text())
      // Indirect eval always runs in the global scope, like jQuery.globalEval.
      .then((js) => (0, eval)(js))
      .finally(() => $(form).trigger("ajax:complete"))
  }
}
