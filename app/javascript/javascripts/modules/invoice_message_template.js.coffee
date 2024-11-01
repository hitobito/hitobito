$(document).on('change', '#invoice_message_template_id', (event) ->
  selectedOption = $(this).find('option:selected')
  form = $(this).closest('form')
  targets = { title: form.find('#invoice_title'), description: form.find('#invoice_description') }
  targets.title?.val(selectedOption?.data('title') || '')
  targets.description?.val(selectedOption?.data('description') || '')
)

