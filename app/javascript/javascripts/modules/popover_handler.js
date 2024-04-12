// Copyright (c) 2023 Hitobito AG. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito.

(function() {
  // this popover handling is confusing but seems to work when disposing and recreating
  // see https://getbootstrap.com/docs/5.0/components/popovers/
  $(document).on('turbo:load', function() {
    $(document).on('click', '.popover button:submit', function(e) {
      $(e.target).closest('.popover').hide();
    });

    $(document).on('click', '.popover a.cancel', function(e) {
      e.preventDefault();
      $(e.target).closest('.popover').hide();
    })

    $(document).on('click', '[data-bs-toggle="popover"]', function(e) {
      $('.popover').hide();
      const el = $(e.target).closest('[data-bs-toggle="popover"]');
      const instance = Popover.getInstance(el);
      if(instance) {
        instance.dispose();
      }
      Popover.getOrCreateInstance(el,
        {
          container: 'body',
          sanitize: false,
          html: true
        }
      ).show();
    })
  });
}).call(this);
