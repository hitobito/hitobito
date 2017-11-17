
app = window.App ||= {}

app.Invoices = {
  toggle: (e) ->
    checked = e.target.checked
    table = $(e.target).closest('table[data-checkable]')
    table.find('tbody :checkbox').prop('checked', checked)

  submit: (e) ->
    e.preventDefault()
    form = $(e.target).closest('form')
    form.append('<input name="_method" value="' + $(e.target).data('method') + '" type="hidden" />')
    form.submit()

  recalculate: (e) ->
    form = $(e.target).closest('form')
    console.log('recalculate')
    $.ajax(url: "#{form.attr('action')}/new?#{form.serialize()}", dataType: 'script')
}

$(document).on('click', 'table[data-checkable] thead :checkbox', app.Invoices.toggle)
$(document).on('click', 'form[data-checkable] button[type=submit]', app.Invoices.submit)
$(document).on('change', '#invoice_items_fields :input', app.Invoices.recalculate)
$(document).on('nested:fieldRemoved:invoice_items', 'form', app.Invoices.recalculate)
