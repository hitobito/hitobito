//  Copyright (c) 2015 Pro Natura Schweiz. This file is part of
//  hitobito and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/hitobito/hitobito.

(function() {
  var app = window.App || (window.App = {});

  app.setupQuicksearch = function() {
    var qs;
    qs = $('#quicksearch');
    return setupRemoteTypeahead(qs);
  };

  app.setupEntityTypeahead = function() {
    var input = $(this);
    setupRemoteTypeahead(input);
  };

  function setupRemoteTypeahead(input) {
    input.attr('autocomplete', "off");
    let autoCompleteInput = new autoComplete({
      selector: '#' + input[0].id ,
      placeHolder: input[0].placeholder,
      data: {
        src: async (query) => {
          try {
            if (input[0].id === "quicksearch") {
              document.getElementById("quicksearch").classList.add('input-loading')
            }
            let url = document.getElementById(input[0].id).dataset.url
            let queryKey = document.getElementById(input[0].id).dataset.param || 'q';
            const source = await fetch(
              url + '?' + queryKey + '=' + query
            );
            const data = await source.json();

            if (input[0].id === "quicksearch") {
              document.getElementById("quicksearch").classList.remove('input-loading')
            }
            return data;
          } catch (error) {
            return error;
          }
        },
      },
      resultsList: {
        noResults: true,
        maxResults: 15,
        tabSelect: true
      },
      events: {
        input: {
          selection: (event) => {
            var selection = event.detail.selection.value;
            if (event.target.id === "quicksearch") {
              var urlKey = event.detail.selection.value.type + "Url"
              window.location = event.target.dataset[urlKey] + '/' + event.detail.selection.value.id;
              autoCompleteInput.input.value = selection.label + " wird geöffnet..."
            } else {
              autoCompleteInput.input.value = selection.label;
              document.getElementById(adjustSelector(autoCompleteInput.input.dataset.idField)).value = selection.id;
              if (document.getElementById(autoCompleteInput.input.dataset.idField).dataset.url) {
                getIdFieldUrl(document.getElementById(autoCompleteInput.input.dataset.idField))
              }
            }
          }
        }
      },
      debounce: 450,
      threshold: 3,
      searchEngine: function(query, record) {
        return labelWithIcon(record.icon, highlightQuery(record.label, query))
      }
    });
  };

  function highlightQuery(label, query) {
    const words = query.trim().split(/\s+/);

    for (const word of words) {
      if (word.trim() === "") continue;
      const regex = new RegExp('(' + word.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&') + ')', 'ig');
      label = label.replace(regex, '<strong>$1</strong>');
    }

    return label;
  }

  function getIdFieldUrl(idField) {
    let idFieldUrl = idField.dataset.url
    let name = idField.name
    let id = idField.value
    $.ajax({
      url: idFieldUrl + '?' + name + '=' + id,
      method: 'GET'
    });
  }

  function labelWithIcon(icon, label) {
    if (icon) {
      return '<i class="fa fa-' + icon + '"></i> ' + label;
    } else {
      return label;
    }
  }

  function adjustSelector(selector) {
    return selector.replace(/\]_|\]\[|\[|\]/g, '_')
  }

  // set insertFields function for nested-form gem
  window.nestedFormEvents.insertFields = function(content, assoc, link) {
    var el = $(link).closest('form').find("#" + assoc + "_fields");
    var nel = el.append($(content));
    nel.find('[data-provide=entity]').each(app.setupEntityTypeahead);
    return nel;
  };

  $(document).on('turbolinks:load', function() {
    app.setupQuicksearch();
    $('[data-provide=entity]').each(app.setupEntityTypeahead);
    return $('[data-provide]').each(function() {
      return $(this).attr('autocomplete', "off");
    });
  });

}).call(this);
