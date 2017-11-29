app = window.App ||= {}

app.InvoiceArticles = {
  add: (e) ->
    url = $('form[data-group').data('group')
    articleAction = "#{url}/invoice_articles/#{e.target.value}.json"
    $.ajax(url: articleAction, dataType: 'json', success: app.InvoiceArticles.updateForm)
    e.target.value = undefined # reset field as preparation for next addition

  updateForm: (data, status, req) ->
    $('.add_nested_fields').first().click() # add new lineitem
    fields = $('#invoice_items_fields .fields').last().find('input, textarea')
    fields.each (idx, elm) ->
      name = elm.name.match(/\d\]\[(.*)\]$/)[1]
      elm.value = data[name] if data[name]
    app.Invoices.recalculate()

}

$(document).on('change', '#invoice_item_article', app.InvoiceArticles.add)
