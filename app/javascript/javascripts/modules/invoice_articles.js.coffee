app = window.App ||= {}

app.InvoiceArticles = {
  add: (e) ->
    url = $('form[data-group').data('group')
    if e.target.value == 'variable_donation'
      selectedOption = e.target.options[e.target.selectedIndex]
      variableDonationObj = { name: selectedOption.dataset.name, description: selectedOption.dataset.description, variable_donation: true }
      app.InvoiceArticles.updateForm(variableDonationObj)
    else if e.target.value
      articleAction = "#{url}/invoice_articles/#{e.target.value}.json"
      $.ajax(url: articleAction, dataType: 'json', success: app.InvoiceArticles.updateForm)
    e.target.value = undefined # reset field as preparation for next addition

  updateForm: (data, status, req) ->
    $('.add_nested_fields').first().click() # add new lineitem
    fields = $('#invoice_items_fields .fields').last().find('input, textarea')
    fields.each (idx, elm) ->
      name = elm.name.match(/\d\]\[(.*)\]$/)[1]
      elm.value = data[name] if data[name]

      if data.variable_donation
        switch name
          when 'unit_cost', 'var_rate'
            elm.style.visibility = 'hidden'
            elm.value = 0
          when 'count'
            elm.style.visibility = 'hidden'
            elm.value = 1
          when 'variable_donation'
            elm.value = 'true'

    app.Invoices.recalculate()

}

$(document).on('change', '#invoice_item_article', app.InvoiceArticles.add)
