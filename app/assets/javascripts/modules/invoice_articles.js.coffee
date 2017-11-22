app = window.App ||= {}

app.InvoiceArticles = {
  add: (e) ->
    $.ajax(url: "/invoice_articles/#{e.target.value}.json", dataType: 'json', success: app.InvoiceArticles.updateForm)
    e.target.value = undefined # reset field as preparation for next addition

  updateForm: (data, status, req) ->
    $('.add_nested_fields').first().click() # add new lineitem

    mapping = {
      name: 'name',
      description: 'description',
      vat_rate: 'vat_rate',
      unit_cost:'net_price'
    }
    $('#invoice_items_fields .fields').last().find('input,textarea').each (idx, elm) ->
      name = elm.name.match(/\d\]\[(.*)\]$/)[1]
      elm.value = data[mapping[name]] if mapping[name]
}

$(document).on('change', '#invoice_item_article', app.InvoiceArticles.add)
