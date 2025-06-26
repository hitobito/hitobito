// Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import { Controller } from "@hotwired/stimulus";

// Currently (Sep '24) we are not able to import libraries using webpacker inside wagons.
// Therefore we place wagon stimulus controllers in core until webpacker is replaced.

export default class extends Controller {
  static values = {
    url: String,
    confirm: String,
    alertUnsaved: String,
  };

  pushDown(event) {
    event.preventDefault();
    const control = this.#getControl(event);
    if (this.#isUnchanged(control)) {
      const field = control.name.match(/event_kind\[(.+?)\]/)[1];
      confirm(this.confirmValue) && this.#pushDownField(field);
    } else {
      alert(this.alertUnsavedValue);
    }
  }

  #getControl(event) {
    return event.target
      .closest(".labeled")
      .querySelector("input:not([type=hidden]), select, textarea");
  }

  #isUnchanged(control) {
    switch (control.type) {
      case "checkbox":
        return control.checked === control.defaultChecked;
      case "select-one":
        const defaultOption = Array.from(control.options).find(
          (option) => option.defaultSelected
        );
        return control.value === defaultOption.value;
      default:
        return control.value === control.defaultValue;
    }
  }

  #pushDownField(field) {
    fetch(`${this.urlValue}/${field}`, {
      method: "PUT",
      headers: {
        Accept: "application/json",
        "X-CSRF-Token": this.#csrfToken(),
      },
    })
      .then((r) => r.json())
      .then((json) => this.#showFlashNotice(json.notice));
  }

  #showFlashNotice(message) {
    if (!message) return;

    const container = document.createElement("div");
    container.innerHTML = `<div class="alert alert-success alert-dismissible fade show">
      <button aria-label="Schliessen" class="btn-close" data-bs-dismiss="alert" type="button"></button>
      <p>${message}</p></div>`;
    document
      .getElementById("flash")
      .replaceChildren(container.firstElementChild);
    document.scrollingElement.scrollTo(0, 0);
  }

  #csrfToken() {
    return document.querySelector('[name="csrf-token"]')?.content;
  }
}
