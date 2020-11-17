#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

app.EventKindPreconditions = {

  showFields: (e) ->
    e.preventDefault()
    $('#event_kind_precondition_kind_ids').val([])
    $('#add_precondition_grouping').hide()
    $('#precondition_fields').slideDown()

  hideFields: (e) ->
    e.preventDefault()
    $('#precondition_fields').slideUp()
    $('#add_precondition_grouping').show()

  removePreconditions: (e) ->
    e.preventDefault()
    $(this).parents('.precondition-grouping').remove()
    $('.precondition-grouping:first-child .muted').remove()

  addPreconditions: (e) ->
    e.preventDefault()
    obj = app.EventKindPreconditions
    ids = $('#event_kind_precondition_kind_ids').val()
    if ids.length
      grouping = $('.precondition-grouping').length
      html = '<div class="precondition-grouping">' +
        ids.map((id) -> obj.buildHiddenField(grouping, id)).join(' ') +
        obj.buildConjunction(grouping) +
        obj.buildSentence() +
        obj.buildRemoveLink() +
        '</div>'
      $('#add_precondition_grouping').before(html)
    obj.hideFields(e);


  buildHiddenField: (grouping, id) ->
    '<input name="event_kind[precondition_qualification_kinds][' + grouping +
      '][qualification_kind_ids][]" type="hidden" value="' + id + '" />'

  buildConjunction: (grouping) ->
    if grouping
      '<span class="muted">' + $('#precondition_summary').data('or') + '</span> '
    else
      ''

  buildRemoveLink: ->
    ' <a href="#" class="remove-precondition-grouping"><i class="icon icon-trash"></i></a>'

  buildSentence: ->
    labels = app.EventKindPreconditions.fetchLabels()
    last = labels.pop()
    if labels.length
      labels.join(', ') + ' ' + $('#precondition_summary').data('and') + ' ' + last
    else
      last

  fetchLabels: ->
    labels = []
    $('#event_kind_precondition_kind_ids option:selected').each((i, option) ->
      labels.push($(option).text()))
    labels
}

$(document).on('click', '#add_precondition_grouping', app.EventKindPreconditions.showFields)
$(document).on('click', '#precondition_fields .cancel', app.EventKindPreconditions.hideFields)
$(document).on('click', '#precondition_fields button', app.EventKindPreconditions.addPreconditions)
$(document).on('click', '.remove-precondition-grouping', app.EventKindPreconditions.removePreconditions)
