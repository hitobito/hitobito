// Copyright (c) 2026, Hitobito AG. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito.

document.addEventListener('turbo:load', setupInvoiceMessageTemplateSelect)

function setupInvoiceMessageTemplateSelect() {
  document.querySelectorAll('[data-message-template-id]').forEach(element => {
    element.addEventListener('change', function(event) {
      const selectedOption = event.target.selectedOptions[0];
      const form = event.target.closest('form');
      form.querySelectorAll('[data-message-template-target]').forEach(targetElement => {
        targetElement.value = selectedOption?.dataset[targetElement.dataset.messageTemplateTarget] || ''
      })
    })
  });
}
