// Copyright (c) 2025, Hitobito AG. This file is part of
// hitobito_sac_cas and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import {Controller} from "@hotwired/stimulus";


export default class extends Controller {

  connect() {
    this.elementAdded(this.element)
  }

  elementAdded(element) {
    var app;

    app = window.App || (window.App = {});
    app.tomSelects = {};

    if(getComputedStyle(element.parentElement.parentElement.parentElement).display !== 'none'
      && element.tomselect === undefined) {
      app.tomSelects[element.id] = new TomSelect(`#${element.id}`, {
        plugins: element.multiple ? ["remove_button"] : [],
        create: false,
        allowEmptyOption: true,
        onItemAdd() {
          this.setTextboxValue("");
        },
      });
    }
  }
}
