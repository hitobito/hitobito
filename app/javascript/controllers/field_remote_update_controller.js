// Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
// hitobito_sac_cas and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import { Controller } from "@hotwired/stimulus"

// This controller can update form field values on changes to other form fields
// Example for usage event/courses/invoices/new.html.haml in sac wagon

export default class extends Controller {
  static targets = ["field"]

  sourceChanged(event) {
    console.log("ALARM");
    const fieldName = event.target.name;
    const fieldValue = event.target.value;
    const url = this.element.dataset.url;

    const queryParam = encodeURIComponent(fieldName) + "=" + encodeURIComponent(fieldValue);

    fetch(`${url}?${queryParam}`, {
      headers: { "Accept": "application/json" }
    })
    .then(response => response.json())
    .then(data => {
      if (this.hasFieldTarget && data.value) {
        this.fieldTarget.value = data.value;
      }
    })
    .catch(error => console.error("Error:", error));
  }
}
