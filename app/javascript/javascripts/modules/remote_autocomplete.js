//  Copyright (c) 2015 Pro Natura Schweiz. This file is part of
//  hitobito and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/hitobito/hitobito.

import autoComplete from "@tarekraafat/autocomplete.js";
import { mark } from "@tarekraafat/autocomplete.js/src/helpers/io";

(function() {
  const QUICKSEARCH_ID = "quicksearch";
  var app = window.App || (window.App = {});

  app.setupQuicksearch = function() {
    const input = document.getElementById(QUICKSEARCH_ID);


    if(input) {
      input.addEventListener('keydown', function(event) {
        if (event.key === 'Enter' && (event.target.getAttribute('aria-activedescendant') == null || event.target.wrapper.getAttribute('aria-expanded') == false)) {
          window.location = `/full?q=${event.target.value}`;
        }
      });
      return setupRemoteTypeahead(input);
    }

  };

  app.setupEntityTypeahead = function() {
    const input = $(this)[0];
    setupRemoteTypeahead(input);
  };

  function setupRemoteTypeahead(input) {
    input.setAttribute("autocomplete", "off");
    const submit = Boolean(input.dataset.submit);
    const isQuickSearch = input.id === QUICKSEARCH_ID;

    let autoCompleteInput = new autoComplete({
      selector: `#${input.id}`,
      placeHolder: input.placeholder,
      submit,
      data: {
        src: async (query) => {
          if (input.dataset.typeaheadDisabled === "true") return;

          try {
            if (isQuickSearch) {
              document.getElementById(QUICKSEARCH_ID).classList.add("input-loading");
            }

            // Fetch data via AJAX request
            const url = new URL(input.dataset.url, location.origin)
            const queryKey = document.getElementById(input.id).dataset.param || "q";
            url.searchParams.set(queryKey, query)
            const source = await fetch(url);
            const data = await source.json();

            if (isQuickSearch) {
              document.getElementById(QUICKSEARCH_ID).classList.remove("input-loading");
            }
            return data;
          } catch (error) {
            return error;
          }
        },
      },
      resultsList: {
        noResults: false,
        maxResults: 15,
        tabSelect: true,
      },
      resultItem: {
        highlight: true,
      },
      events: {
        input: {
          selection: (event) => {
            var selection = event.detail.selection.value;
            autoCompleteInput.input.value = selection.label;

            if (isQuickSearch) {
              // Visit selected entry
              var urlKey = `${event.detail.selection.value.type}Url`;
              window.location = `${event.target.dataset[urlKey]}/${event.detail.selection.value.id}`;
            } else {
              if (input.dataset.updater) {
                // Call custom updater function
                var updater = autoCompleteInput.input.dataset.updater;
                const updaterFunction = updater.split(".").reduce((result, part) => result[part], app);
                input.value = updaterFunction(JSON.stringify(selection));
              } else if(autoCompleteInput.input.dataset.idField) {
                // Assign id value to hidden id field
                const idField = document.getElementById(adjustSelector(autoCompleteInput.input.dataset.idField));
                idField.value = selection.id;

                if (idField.dataset.url) {
                  fetchIdFieldUrl(idField)
                }
              }
            }
          },
          keydown: (event) => {
            if (event.key === 'Enter' && (event.target.getAttribute('aria-activedescendant') == null || event.target.wrapper.getAttribute('aria-expanded') == false)) {
              return true;
            }
          }
        }
      },
      debounce: 450,
      threshold: 3,
      searchEngine: function(query, record) {
        // Render item with icon (if present), applying autocomplete.js' highlight function
        return labelWithIcon(record.icon, record.label.replace(query, mark(query)))
      }
    });
  }

  /**
   * Executes an AJAX GET request to the URL defined on the
   * idField. The result may contain JavaScript, that will be
   * interpreted to perform an action after selection (e.g. update
   * UI).
   */
  function fetchIdFieldUrl(idField) {
    const url = new URL(idField.dataset.url, location.origin);
    url.searchParams.set(idField.name, idField.value);
    $.ajax({
      url,
      method: 'GET'
    })
  }

  app.setupStaticTypeahead = function() {
    const input = $(this)[0];
    input.setAttribute("autocomplete", "off");

    new autoComplete({
      selector: `#${input.id}`,
      data: {
        src: input.dataset.source ? JSON.parse(input.dataset.source) : [],
      },
      resultsList: {
        tabSelect: true,
      },
      resultItem: {
        highlight: true,
      },
      events: {
        input: {
          selection: (event) => {
            // On selection, assign item value to input
            var selection = event.detail.selection.value;
            input.value = selection;
          }
        }
      },
    });
  };

  function labelWithIcon(icon, label) {
    return icon ? `<i class="fa fa-${icon}"></i> ${label}` : label;
  }

  function adjustSelector(selector) {
    return selector.replace(/\]_|\]\[|\[|\]/g, '_')
  }

  // set insertFields function for nested-form gem
  window.nestedFormEvents.insertFields = function(content, assoc, link) {
    var el = $(link).closest('form').find(`#${assoc}_fields`);
    var nel = el.append($(content));
    nel.find("[data-provide=entity]").each(app.setupEntityTypeahead);
    return nel;
  };

  $(document).on("turbo:load turbo:frame-load", function() {
    app.setupQuicksearch();
    $("[data-provide=entity]").each(app.setupEntityTypeahead);
    $("[data-provide=typeahead]").each(app.setupStaticTypeahead);
    return $("[data-provide]").each(function() {
      return $(this).attr("autocomplete", "off");
    });
  });


}).call(this);
