
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
    form = $('form[data-group')
    $.ajax(url: "#{form.data('group')}/invoice_list/new?#{form.serialize()}", dataType: 'script')

  buildPdfExportLink: (e) ->
    invoiceIds = []
    checkedBoxes = $('tbody :checked')
    for cb in checkedBoxes
      invoiceIds.push($(cb).attr('value'))

    href = $(e.target).attr('href')
    separator = if href.indexOf('?') != -1 then '&' else '?'
    param = separator + 'invoice_ids=' + invoiceIds
    $(e.target).attr('href',  href + param)
}

$(document).on('click', 'table[data-checkable] thead :checkbox', app.Invoices.toggle)
$(document).on('click', 'form[data-checkable] button[type=submit]', app.Invoices.submit)
$(document).on('input', '#invoice_items_fields :input[data-recalculate]', app.Invoices.recalculate)
$(document).on('nested:fieldRemoved:invoice_items', 'form', app.Invoices.recalculate)
