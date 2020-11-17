# wire up auto submit fields

$(document).on('change', '[data-submit]', (e) ->
  form = $(this).closest('form')
  if form.attr('method') == 'get'
    Turbolinks.visit("#{form.attr('action')}?#{form.serialize()}", action: 'replace')
  else
    form.submit()
)
