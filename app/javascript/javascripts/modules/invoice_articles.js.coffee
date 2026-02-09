app = window.App ||= {}

app.InvoiceArticles = {
  add: (e) ->
    url = e.target.closest('form').dataset['group']
    if e.target.value
      articleAction = "#{url}/invoice_articles/#{e.target.value}.json"
      $.ajax(url: articleAction, dataType: 'json', success: app.InvoiceArticles.updateForm)
    e.target.value = undefined # reset field as preparation for next addition

  updateForm: (data, status, req) ->
    document.querySelector('[data-action="nested-form#add"]').click() # add new lineitem
    fields = $('#invoice_items_fields .fields').last().find('input, textarea')
    fields.each (idx, elm) ->
      name = elm.name.match(/\d\]\[(.*)\]$/)[1]
      elm.value = data[name] if data[name]

    app.Invoices.recalculate()

}

$(document).on('change', '#invoice_item_article', app.InvoiceArticles.add)
