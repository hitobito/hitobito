app = window.App ||= {}

app.AddressTypeahead = {

  update: (json_response) ->
    data = JSON.parse(json_response)
    form = $('.address-input-fields').closest('form')
    app.AddressTypeahead.find_form_element(form, 'zip_code').value = data.zip_code
    app.AddressTypeahead.find_form_element(form, 'town').value = data.town
    [data.street, data.number || ''].filter(Boolean).join(' ')

  checkIfTypeaheadAvailable: (e) ->
    typeaheadSupportedCountries = JSON.parse(e.target.dataset.typeaheadSupportedCountries)
    form = $('.address-input-fields').closest('form')
    addressField = app.AddressTypeahead.find_form_element(form, 'address')
    addressField.dataset.typeaheadDisabled = !typeaheadSupportedCountries.includes(e.target.value)

  find_form_element: (form, field) ->
    form[0].querySelector('[name$="[' + field + ']"]')

}

$(document).on('change', '#person_country', app.AddressTypeahead.checkIfTypeaheadAvailable)
