// Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito.

(function() {
  var app;

  app = window.App || (window.App = {});
  app.tomSelects = {};

  app.activateTomSelect = function(element) {
    app.tomSelects[element.id] = new TomSelect(`#${element.id}`, {
      plugins: isMultipleSelect(element) ? ["remove_button"] : undefined,
      create: false,
      onItemAdd() {
        this.setTextboxValue("");
        this.refreshOptions();
      },
    });
  };

  function isMultipleSelect(element) {
    return element.nodeName === "INPUT" || element.nodeName === "SELECT" && element.getAttribute("multiple")
  }

  $(document).on('turbolinks:load', function() {
    // enable tom-select
    document.querySelectorAll(".tom-select").forEach(app.activateTomSelect);
  });

  // enable tom select on popover open event
  document.addEventListener("shown.bs.popover", () => {
    document.querySelectorAll('.popover .tom-select').forEach(app.activateTomSelect)
  });
}).call(this);
