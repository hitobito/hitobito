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
