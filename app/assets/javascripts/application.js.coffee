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
#= require jquery-ui
#= require bootstrap
#= require jquery_nested_form
#= require jquery-ui-datepicker-i18n
#= require_self
#

# scope for global functions
window.Application ||= {}

replaceContent = (e, data, status, xhr) ->
  replace = $(this).data('replace')
  el = if replace is true then $(this).closest('form') else $("##{replace}")
  console.warn "found no element to replace" if el.size() is 0
  el.html(data)

setDataType = (xhr) ->
  $(this).data('type', 'html')
  
showDatePicker = (field) ->
   field.datepicker()
   field.datepicker('show')
   
# type aheads

setupRemoteTypeahead = (input, items, updater) ->
  input.attr('autocomplete', "off")
  input.typeahead(
         source: queryForTypeahead,
         updater: updater,
         matcher: (item) -> true, # match every value returned from server
         sorter: (items) -> items, # keep order from server
         items: items,
         highlighter: typeaheadHighlighter)
         
queryForTypeahead = (query, process) ->
  return [] if query.length < 3
  $.get(this.$element.data('url'), { q: query }, (data) ->
    json = $.map(data, (item) -> JSON.stringify(item))
    return process(json)
  )
  
typeaheadHighlighter = (item) ->
  query = this.query.trim().replace(/[\-\[\]{}()*+?.,\\\^$|#]/g, '\\$&')
  query = query.replace(/\s+/g, '|')
  JSON.parse(item).label.replace(new RegExp('(' + query + ')', 'ig'), ($1, match) -> '<strong>' + match + '</strong>')

setupPersonTypeahead = (index, field) ->
  input = $(this)
  input.data('url', '/people/query')
  setupRemoteTypeahead(input, 10, setPersonId)
  input.keydown((event) -> 
    if isModifyingKey(event.which)
      $('#' + input.data('id-field')).val(null))

setPersonId = (item) ->
  typeahead = this
  item = JSON.parse(item)
  idField = $('#' + typeahead.$element.data('id-field'))
  idField.val(item.id)
  item.label

setupQuicksearch = ->
  qs = $('#quicksearch')
  qs.data('url', '/query')
  setupRemoteTypeahead(qs, 20, openQuicksearchResult)

openQuicksearchResult = (item) ->
  typeahead = this
  item = JSON.parse(item)
  url = typeahead.$element.data(item.type + "-url")
  if url
    window.location =  url + '/' + item.id
    label = $('<div/>').html(item.label).text()
    label + " wird geöffnet..."

isModifyingKey = (k) ->
  ! (k == 20 || # Caps lock */
     k == 16 || # Shift */
     k == 9  || # Tab */
     k == 13 || # Enter
     k == 27 || # Escape Key
     k == 17 || # Control Key
     k == 91 || # Windows Command Key
     k == 19 || # Pause Break
     k == 18 || # Alt Key
     k == 93 || # Right Click Point Key
     ( k >= 35 && k <= 40 ) || # Home, End, Arrow Keys
     k == 45 || # Insert Key
     (k >= 33 && k <= 34 )  || # Page Down, Page Up
     (k >= 112 && k <= 123) || # F1 - F12
     (k >= 144 && k <= 145 ))  # Num Lock, Scroll Lock

Application.moveElementToBottom = (elementId, targetId, callback) ->
  $target = $('#' + targetId)
  left = $target.offset().left
  top = $target.offset().top + $target.height()
  $element = $('#' + elementId)
  leftOld = $element.offset().left
  topOld = $element.offset().top
  $element.children().each((i, c) -> $c = $(c); $c.css('width', $c.width()))
  $element.css('left', leftOld)
  $element.css('top', topOld)
  $element.css('position', 'absolute')
  $element.animate({left: left, top: top}, 300, callback)


$ ->
  # wire up quick search
  setupQuicksearch()
  
  # wire up date picker
  $(":input.date").live("click", -> showDatePicker($(this)))
  $(".controls .icon-calendar").live("click", -> showDatePicker($(this).parent().siblings('.date')))
    
  # wire up elements with ajax replace
  $('body').on('ajax:success','[data-replace]', replaceContent)
  $('body').on('ajax:before','[data-replace]', setDataType)
  
  # wire up person auto complete
  $('[data-provide=person]').each(setupPersonTypeahead)
  $('[data-provide]').each(() -> $(this).attr('autocomplete', "off"))
    
  # set insertFields function for nested-form gem
  window.nestedFormEvents.insertFields = (content, assoc, link) ->
    $(link).closest('form').find("##{assoc}_fields").append($(content))

  # show alert if ajax requests fail
  $(document).on('ajax:error', (event, xhr, status, error) ->
    alert('Sorry, something went wrong\n(' + error + ')'))


  # controll visibilty of group contact fields in relation to contact
  $('#group_contact_id').on('change', do ->
    open = !$('#group_contact_id').val()
    ->
      state = !$(this).val()
      $('fieldset.info').slideToggle() if open != state
      open = state
  )
