var app;

app = window.App || (window.App = {});

app.AddressTypeahead = {
  update: function(json_response) {
    var data, form;
    data = JSON.parse(json_response);
    form = $('.address-input-fields').closest('form');
    app.AddressTypeahead.find_form_element(form, 'zip_code').value = data.zip_code;
    app.AddressTypeahead.find_form_element(form, 'town').value = data.town;
    return [data.street, data.number || ''].filter(Boolean).join(' ');
  },
  checkIfTypeaheadAvailable: function(e) {
    var addressField, form, typeaheadSupportedCountries;
    typeaheadSupportedCountries = JSON.parse(e.target.dataset.typeaheadSupportedCountries);
    form = $('.address-input-fields').closest('form');
    addressField = app.AddressTypeahead.find_form_element(form, 'address');
    return addressField.dataset.typeaheadDisabled = !typeaheadSupportedCountries.includes(e.target.value);
  },
  find_form_element: function(form, field) {
    return form[0].querySelector('[name$="[' + field + ']"]');
  }
};

$(document).on('change', '#person_country', app.AddressTypeahead.checkIfTypeaheadAvailable);

