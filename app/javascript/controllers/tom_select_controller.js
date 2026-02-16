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

    data-tom-select-optgroup-field-value: The name of the optgroup value field in the options.
      If not set, the default is "group".

    data-tom-select-options-value: An array of JSON objects containing the available options.
      Object should contain an id, label and optional description property.
      If not set, the options from the HTML are used.

    data-tom-select-optgroups-value: An array of JSON objects containing the available option
      groups. Objects should contain a value and a label property.
      If not set, the optgroups from the HTML are used.

    data-tom-select-optgroups-header-value: A String representing a valid js function body.
      It should return a function that takes a opt group object and renders the corresponding HTML string, i.e

        return function(data) {
          return `<div class="optgroup-header`>${data.label}</div>`
        }

    data-tom-select-selected-value: An array of ids containing the selected options.
      If not set, the selected options from the HTML are used.

    data-tom-select-no-results-value: The message to display when no results are found.
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
    optgroupField: { type: String, default: "group" },
    options: { type: Array },
    optgroups: { type: Array },
    selected: { type: Array },
    noResults: { type: String, default: "No results found." },
    maxOptions: { type: Number, default: null }, // no limit by default (null)
    optgroupsHeader: String,
  };

  connect() {
    this.tom = new TomSelect(`#${this.element.id}`, this.#getOptions());
    this.tom.on("item_add", this.#clearInput.bind(this));
    if (this.element.autofocus) {
      this.tom.focus();
    }
  }

  #getOptions() {
    const multiple =
      this.element.nodeName === "SELECT" &&
      this.element.getAttribute("multiple");

    const options = {
      valueField: "id",
      labelField: this.labelValue,
      searchField: this.labelValue,
      optgroupField: this.optgroupFieldValue,
      plugins: multiple ? ["remove_button"] : undefined,
      create: false,
      load: this.urlValue ? this.#load.bind(this) : undefined,
      maxOptions: this.maxOptionsValue,
      render: {
        no_results: this.#renderNoResults.bind(this),
        option: this.#renderOption.bind(this),
      },
    };
    if (this.optionsValue.length) options.options = this.optionsValue;
    if (this.optgroupsValue.length) options.optgroups = this.optgroupsValue;
    if (this.selectedValue.length) options.items = this.selectedValue;
    if (this.optgroupsHeaderValue.length)
      options.render.optgroup_header = Function(this.optgroupsHeaderValue)();

    return options;
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

  #renderNoResults() {
    return `<div class='no-results'>${this.noResultsValue}</div>`;
  }

  #optGroupHeader(data) {
    if (!data.color) {
      return `<div class="optgroup-header">${data.label}</div>`;
    }
    return `<div class="optgroup-header"><i style="color: ${data.color}" class="fas fa-circle"></i><span class="ms-1">${data.label}</span></div>`;
  }

  #renderOption(data, escape) {
    let label = `<div>${escape(data[this.labelValue])}</div>`;
    if (data.description) {
      const desc = `<div class="muted small">${escape(data.description)}</div>`;
      label = `<div>${label}${desc}</div>`;
    }
    return label;
  }
}
