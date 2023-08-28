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
            var selection = event.detail.selection.value.label;
            if (event.target.id === "quicksearch") {
              var urlKey = event.detail.selection.value.type + "Url"
              window.location = event.target.dataset[urlKey] + '/' + event.detail.selection.value.id;
              autoCompleteInput.input.value = selection + " wird geöffnet..."
            } else {
              autoCompleteInput.input.value = selection;
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
    query = query.trim().replace(/[\-\[\]{}()*+?.,\\\^$|#]/g, '\\$&');
    return label.replace(new RegExp('(' + query + ')', 'ig'), function($1, match) {
      return '<strong>' + match + '</strong>';
    });
  }

  function labelWithIcon(icon, label) {
    if (icon) {
      return '<i class="fa fa-' + icon + '"></i> ' + label;
    } else {
      return label;
    }
  }

  $(document).on('turbolinks:load', function() {
    app.setupQuicksearch();
    $('[data-provide=entity]').each(app.setupEntityTypeahead);
    return $('[data-provide]').each(function() {
      return $(this).attr('autocomplete', "off");
    });
  });

}).call(this);
