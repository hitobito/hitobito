// Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito.

(function() {
  var app;

  app = window.App || (window.App = {});

  app.activateTomSelect = function(i, element) {
    return app.tomSelect = new TomSelect('#' + element.id, {
      plugins: ['remove_button'],
      create: false,
      onItemAdd: function() {
        this.setTextboxValue('');
        this.refreshOptions();
      },
      render: {
        option: function(data, escape) {
          return '<div class="d-flex"><span>' + escape(data.text) + '</span></div>';
        },
        item: function(data, escape) {
          return '<div>' + escape(data.text) + '</div>';
        }
      }
    });
  };

  $(document).on('turbolinks:load', function() {
    // enable tom-select
    $('.tom-select').each(app.activateTomSelect);
    $('#group-filter-clear').on('click', function() {
      return app.tomSelect.clear();
    });
    return $('#group-filter-add').on('click', function() {
      return app.tomSelect.add();
    });
  });

  // enable tom select on popover open event
  $(document).on('shown.bs.popover', function() {
    return $('.popover .tom-select').each(app.activateTomSelect);
  });

}).call(this);
