document.addEventListener('turbo:load', setupInvoiceMessageTemplateSelect)

function setupInvoiceMessageTemplateSelect() {
  document.querySelectorAll('#invoice_message_template_id').forEach(element => {
    element.addEventListener('change', function(event) {
      const selectedOption = event.target.selectedOptions[0];
      const form = event.target.closest('form');
      const targets = {
        title: form.querySelector('#invoice_title'),
        description: form.querySelector('#invoice_description')
      };
      
      targets.title && (targets.title.value = selectedOption?.dataset.title || '');
      targets.description && (targets.description.value = selectedOption?.dataset.description || '');
    })
  });
}
