// Copyright (c) 2026, Puzzle ITC. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import { Controller } from "@hotwired/stimulus";

// A transient modal is shown as soon as it is inserted into the page, e.g. by
// a turbo stream, and removed again after closing. A modal that is still open
// is closed first, so Bootstrap resets the page. Bootstrap ignores closing a
// modal while it fades in, so closing is repeated once it is shown.
//
// Usage: render the modal and insert it into the page, e.g. in a controller
//
//   render turbo_stream: turbo_stream.append("modal-placeholder",
//     partial: "my_modal"), status: :unprocessable_content
//
// Put the controller on the .modal element and wire the cancel link with the
// close action. Without the action, the cancel link does not close the modal:
//
//   #my-modal.modal.fade{ tabindex: -1, data: { controller: 'transient-modal' } }
//     .modal-dialog
//       .modal-content
//         .modal-body
//         .modal-footer
//           = link_to(ti('button.cancel'), '#', class: 'link cancel',
//                     data: { action: 'transient-modal#close' })
//
// Use it only for modals that are added to a page that is already displayed,
// not for modals that are part of the page's own HTML. Those would be shown
// right away when the page loads.
export default class extends Controller {
  connect() {
    const modal = $(this.element);

    // Remove the element once it is closed. Otherwise every modal shown would
    // stay hidden in the page, as turbo streams append instead of replacing.
    modal.one("hidden.bs.modal", () => this.element.remove());

    // Another modal may still be open, e.g. the role selection of the people
    // list whose form submission returned this modal. Bootstrap supports only
    // one open modal at a time.
    const openModal = $(".modal.show").not(this.element).first();
    if (openModal.length) {
      // Show this modal only after the other one is completely hidden. By
      // then Bootstrap has removed its backdrop and the modal-open class of
      // the body, which would otherwise be left behind.
      openModal.one("hidden.bs.modal", () => modal.modal("show"));
      this.hide(openModal);
    } else {
      modal.modal("show");
    }
  }

  close(event) {
    // Do not follow the href "#" of the link, which would scroll to the top.
    event.preventDefault();
    this.hide($(this.element));
  }

  hide(modal) {
    // Bootstrap ignores hiding a modal while its fade-in transition runs. The
    // shown event still follows once the transition ends, so hide it again
    // at that point.
    const hideOnceShown = () => modal.modal("hide");
    modal.one("shown.bs.modal", hideOnceShown);

    // If the modal was already shown, hiding works right away and no shown
    // event follows. Remove the pending handler, so it does not hide the
    // modal immediately when it is shown again later.
    modal.one("hidden.bs.modal", () => modal.off("shown.bs.modal", hideOnceShown));

    modal.modal("hide");
  }
}
