# This is a manifest file that'll be compiled into application.js, which will include all the files
# listed below.
#
# Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
# or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# the compiled file.
#
# WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
# GO AFTER THE REQUIRES BELOW.
#
#= require jquery
#= require jquery_ujs
#= require bootstrap
#= require jquery_nested_form
#= require_tree .
#


replaceContent = (e, data, status, xhr) ->
  replace = $(this).data('replace')
  el = if replace is true then $(this).closest('form') else $("##{replace}")
  console.warn "found no element to replace" if el.size() is 0
  el.html(data)

setDataType = (xhr) ->
  $(this).data('type', 'html')
  
findPeople = (query, process) ->
  return [] if query.length < 3
  typeahead = this
  $.get('/people', { q: query }, (data) ->
    typeahead.selection = data
    names = $.map(data, (person) -> person.name)
    return process(names)
  )

setPersonId = (item) ->
  typeahead = this
  person = $.grep(typeahead.selection, (person) -> person.name == item)[0]
  id_input = $('#' + typeahead.$element.data('id-field'))
  id_input.val(person.id)
  item

setupPersonTypeahead = (input) ->
  $(this).typeahead(source: findPeople, updater: setPersonId)


$ ->
  $('body').on('ajax:success','[data-replace]', replaceContent)
  
  $('body').on('ajax:before','[data-replace]', setDataType)
  
  $('[data-provide=person]').each(setupPersonTypeahead)
  
  $('[data-provide]').each(() -> $(this).attr('autocomplete', "off"))
  
  window.nestedFormEvents.insertFields = (content, assoc, link) ->
    $(link).closest('form').find("##{assoc}_fields").append($(content))
