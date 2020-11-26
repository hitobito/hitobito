app = window.App ||= {}

app.AddressTypeahead = {

  update: (json_response) ->
    data = JSON.parse(json_response)
    form = $('[data-household]').closest('form')
    form.find('#person_zip_code')[0].value = data.zip_code
    form.find('#person_town')[0].value = data.town
    "#{data.street} #{data.number || ''}"
  
  checkIfTypeaheadAvailable: (e) ->
    typeaheadSupportedCountries = JSON.parse(e.target.dataset.typeaheadSupportedCountries)
    form = $('[data-household]').closest('form')
    addressField = form.find('#person_address')[0]
    addressField.dataset.typeaheadDisabled = !typeaheadSupportedCountries.includes(e.target.value)

}

$(document).on('change', '#person_country', app.AddressTypeahead.checkIfTypeaheadAvailable)
