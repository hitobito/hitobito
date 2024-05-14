// Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
// hitobito_sac_cas and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito
//
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    url: String,
    label: { type: String, default: 'label' },
    noResults: { type: String, default: 'No results found.' }
  };

  initialize() {
    this.getOptions = this.#getOptions.bind(this);
    this.clearInput = this.#clearInput.bind(this);
    this.noResults = this.#noResults.bind(this);
    this.load = this.#load.bind(this);
  }

  connect() {
    this.tom = new TomSelect(`#${this.element.id}`, this.getOptions());
    this.tom.on("item_add", this.clearInput);
  }

  #getOptions() {
    const multiple =
      this.element.nodeName === "SELECT" &&
      this.element.getAttribute("multiple");

    return {
      valueField: "id",
      labelField: this.labelValue,
      searchField: this.labelValue,
      plugins: multiple ? ["remove_button"] : undefined,
      create: false,
      load: this.urlValue ? this.load : undefined,
      render: {
        no_results: this.noResults
      }
    };
  }

  #load(query, callback) {
    const url = `${this.urlValue}?q=${encodeURIComponent(query)}`;
    fetch(url)
      .then((response) => response.json())
      .then((json) => {
        callback(json);
      })
      .catch(() => {
        callback();
      });
  }

  #clearInput() {
    const input = document.querySelector(`#${this.element.id}-ts-control`)
    input.value = "";
  }

  #noResults() {
    return `<div class='no-results'>${this.noResultsValue}</div>`
  }
}
