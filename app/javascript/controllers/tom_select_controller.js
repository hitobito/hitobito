// Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
// hitobito_sac_cas and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito
//
import { Controller } from "@hotwired/stimulus";

/*
  To enable TomSelect on a select element, add this data attribute:
    data-controller="tom-select"

  Following value attributes are available to configure TomSelect:

    data-tom-select-url: The URL to fetch options from. This should be a JSON API
      endpoint that returns an array of objects with the following structure:
        [
          { id: 1, label: "Option 1" },
          { id: 2, label: "Option 2" },
          ...
        ]

    data-tom-select-label-value: The name of the label field in the options. If not set,
      the default is "label".

    data-tom-select-no-results-valu: The message to display when no results are found.
      If not set, the default is "No results found.".

    data-tom-select-max-options-value: The maximum number of options to show in the
      dropdown. If not set, it will not limit the option numbers. To limit the listed options,
      set the data-tom-select-max-options attribute to the desired number.
      Regardless of a limit, the user can still select any option when filtering the list
      by typing.

  For example:

    select_content_tag :my_select, options_for_select(@options),
      data: { controller: "tom-select", tom_select_max_options_value: 42 }
 */
export default class extends Controller {
  static values = {
    url: String,
    label: { type: String, default: "label" },
    noResults: { type: String, default: "No results found." },
    maxOptions: { type: Number, default: null } // no limit by default (null)
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
    if (this.element.autofocus) {
      this.tom.focus();
    }
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
      maxOptions: this.maxOptionsValue,
      render: {
        no_results: this.noResults,
      },
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
    const input = document.querySelector(`#${this.element.id}-ts-control`);
    input.value = "";
  }

  #noResults() {
    return `<div class='no-results'>${this.noResultsValue}</div>`;
  }
}
