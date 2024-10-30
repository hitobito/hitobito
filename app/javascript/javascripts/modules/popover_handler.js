// Copyright (c) 2023 Hitobito AG. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito.

(function () {
  // this popover handling is confusing but seems to work when disposing and recreating
  // see https://getbootstrap.com/docs/5.0/components/popovers/
  $(document).on("turbo:load", function () {
    // remote form used in app/views/event/application_market/_popover_waiting_list.html.haml
    // does not trigger form#submit event
    $(document).on(
      "click",
      ".popover form[data-remote] button:submit",
      function (e) {
        $(e.target).closest(".popover").hide();
      },
    );

    // normal forms e.g. sac/event/participations/_popover_cancel_sac do trigger form submit
    // only if form validation pass (allows us to use client side validations)
    $(document).on("click", ".popover form:submit", function (e) {
      $(e.target).closest(".popover").hide();
    });

    $(document).on("click", ".popover a.cancel", function (e) {
      e.preventDefault();
      $(e.target).closest(".popover").hide();
    });

    $(document).on("click", '[data-bs-toggle="popover"]', function (e) {
      $(".popover").hide();
      const toggler = $(e.target).closest('[data-bs-toggle="popover"]')[0];
      const anchor = document.querySelector(toggler.dataset["anchor"]);
      if (anchor) {
        if (!anchor.querySelector(".popover-anchor")) {
          anchor.insertAdjacentHTML("afterbegin", "<div class='popover-anchor' style='width: 100%; height: 0;'></div>");
        }
      }
      const el = anchor.querySelector(".popover-anchor") || toggler;

      const instance = Popover.getInstance(el);
      if (instance) {
        instance.dispose();
      }

      Popover.getOrCreateInstance(el, {
        container: "body",
        sanitize: false,
        html: true,
        content: toggler.dataset.bsContent
      }).show();
    });
  });
}).call(this);
