// Copyright (c) 2023 Hitobito AG. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito.

(function() {
  var app = window.App || (window.App = {});

  app.PopoverHandler = (function() {
    function PopoverHandler() {}

    PopoverHandler.prototype.toggle = function(event) {
      // close all other popovers
      $('[data-bs-toggle=popover]').not(event.target).popover('hide')
    };

    PopoverHandler.prototype.close = function(event) {
      $(event.target).popover('hide')
    };

    PopoverHandler.prototype.bind = function() {
      var self = this;
      $('[data-bs-toggle=popover]').each(function() {
        $(this).popover({
          container: 'body',
          sanitize: false,
          html: true
        })
      });
      $(document).on('click', '[data-bs-toggle=popover]', function(e) {
        self.toggle(e);
      });

      $(document).on('click', '.popover a.cancel', function(e) {
        self.close(e);
      });
      $(document).on('click', '.popover button:submit', function(e) {
        self.close(e);
      });
    };
    return PopoverHandler;
  })();

  $(document).on('turbolinks:load', function() {
    new app.PopoverHandler().bind();
  });

}).call(this);
