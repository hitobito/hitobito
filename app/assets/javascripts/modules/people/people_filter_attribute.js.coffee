- #  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
- #  hitobito and licensed under the Affero General Public License version 3
- #  or later. See the COPYING file at the top-level directory or at
- #  https://github.com/hitobito/hitobito.

app = window.App ||= {}

app.PeopleFilterAttribute = {
  remove: (e) ->
    $(e.target).closest('.people_filter_attribute_form').remove()
    e.preventDefault()

  add: (e) ->
    return if e.target.value == ''
    form = $('.people_filter_attribute_form_template').clone()

    app.PeopleFilterAttribute.duplicateAttributeForm(e, form)
    app.PeopleFilterAttribute.setAttributeNameTimestamp(form)
    app.PeopleFilterAttribute.enableForm(form)

  duplicateAttributeForm: (e, form) ->
    form.removeClass('people_filter_attribute_form_template')
    form.removeClass('hidden')
    form.find('.attribute_key_dropdown').val(e.target.value)
    form.find('.attribute_key_hidden_field').val(e.target.value)
    form.appendTo '#people_filter_attribute_forms'
    e.target.value = ''

  setAttributeNameTimestamp: (form) ->
    time = new Date().getTime()

    app.PeopleFilterAttribute.renameAttributeName(form.find('.attribute_key_hidden_field'), time)
    app.PeopleFilterAttribute.renameAttributeName(form.find('.attribute_constraint_dropdown'), time)
    app.PeopleFilterAttribute.renameAttributeName(form.find('.attribute_value_input'), time)

  renameAttributeName: (selector, time) ->
    regex = /\[\d{13}\]/
    selector.attr('name', selector.attr('name').replace(regex, "[#{time}]"))

  enableForm: (form) ->
    field = form.find('.attribute_key_hidden_field').attr('value')
    type  = form.closest('[data-types]').data('types')[field]

    form.find('option[value=greater], option[value=smaller]').remove() unless type == 'integer'
    form.find('.attribute_key_hidden_field').removeAttr('disabled')
    form.find('.attribute_constraint_dropdown').removeAttr('disabled')
    form.find('.attribute_value_input').removeAttr('disabled')


}

$(document).on('change', '#attribute_filter', app.PeopleFilterAttribute.add)
$(document).on('click', '.remove_filter_attribute', app.PeopleFilterAttribute.remove)
