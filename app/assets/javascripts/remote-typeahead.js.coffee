
# scope for global functions
window.Application ||= {}

Application.setupQuicksearch = ->
  qs = $('#quicksearch')
  setupRemoteTypeahead(qs, 20, openQuicksearchResult)

Application.setupEntityTypeahead = (index, field) ->
  input = $(this)
  setupRemoteTypeahead(input, 10, setEntityId)
  input.keydown((event) ->
    if isModifyingKey(event.which)
      $('#' + adjustSelector(input.data('id-field'))).val(null).change())

# supports using typeahead for nested fields:
# changes person[people_relations_attributes][1407938119241]_tail_id
# to person_people_relations_attributes_1407938119241_tail_id
adjustSelector = (selector) ->
  selector.replace(/\]_|\]\[|\[|\]/g, '_')

setEntityId = (item) ->
  typeahead = this
  item = JSON.parse(item)
  idField = $('#' + adjustSelector(typeahead.$element.data('id-field')))
  idField.val(item.id).change()
  $('<div/>').html(item.label).text()

openQuicksearchResult = (item) ->
  typeahead = this
  item = JSON.parse(item)
  url = typeahead.$element.data(item.type + "-url")
  if url
    window.location =  url + '/' + item.id
    label = $('<div/>').html(item.label).text()
    label + " wird geöffnet..."

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
