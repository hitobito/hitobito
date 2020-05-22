#  Copyright (c) 2015 Pro Natura Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# scope for global functions
app = window.App ||= {}

app.setupQuicksearch = ->
  qs = $('#quicksearch')
  setupRemoteTypeahead(qs, 20, openQuicksearchResult)

app.setupEntityTypeahead = (index, field) ->
  input = $(this)
  updateFunction = setEntityId

  if input.data('updater')
    updateFunction = app
    updateFunction = updateFunction[prop] for prop in input.data('updater').split('.')


  max_items = input.data('max-items') || 10
  setupRemoteTypeahead(input, max_items, updateFunction)
  if input.data('id-field')
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
  if typeahead.$element.data('id-field')
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
         source: delayedQueryForTypeahead,
         updater: updater,
         matcher: (item) -> true, # match every value returned from server
         sorter: (items) -> items, # keep order from server
         items: items,
         highlighter: typeaheadHighlighter)

queryForTypeAhead = (query, process, url)->
  app.request = $.get(url, { q: query }, (data) ->
    json = $.map(data, (item) -> JSON.stringify(item))
    $('#quicksearch').removeClass('input-loading')
    process(json)
  )

delayedQueryForTypeahead = (query, process, delay = 450) ->
  if query.length < 3
    $('#quicksearch').removeClass('input-loading')
    return []

  if app.scheduledTypeahead
    app.scheduledTypeahead = clearTimeout(app.scheduledTypeahead)

  url = this.$element.data('url')
  $('#quicksearch').addClass('input-loading')

  delayedQuery = -> queryForTypeAhead(query, process, url)
  app.scheduledTypeahead = setTimeout(delayedQuery, delay)

typeaheadHighlighter = (item) ->
  query = this.query.trim().replace(/[\-\[\]{}()*+?.,\\\^$|#]/g, '\\$&')
  query = query.replace(/\s+/g, '|')
  labelWithIcon(JSON.parse(item)).replace(new RegExp('(' + query + ')', 'ig'), ($1, match) -> '<strong>' + match + '</strong>')

labelWithIcon = (item) ->
  if item.icon
    '<i class="fa fa-' + item.icon + '"></i> ' + item.label
  else
    item.label

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


# set insertFields function for nested-form gem
window.nestedFormEvents.insertFields = (content, assoc, link) ->
  el = $(link).closest('form').find("##{assoc}_fields")
  nel = el.append($(content))
  nel.find('[data-provide=entity]').each(app.setupEntityTypeahead)
  return nel


# make clicking on typeahead item always select it (https://github.com/twitter/bootstrap/issues/4018)
$(document).on('mousedown', 'ul.typeahead', (e) -> e.preventDefault())

$(document).on('turbolinks:load', ->
  # wire up quick search
  app.setupQuicksearch()

  # wire up person auto complete
  $('[data-provide=entity]').each(app.setupEntityTypeahead)
  $('[data-provide]').each(() -> $(this).attr('autocomplete', "off"))
)
