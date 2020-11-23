#  Copyright (c) 2017 Pro Natura Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

app.EventDescription = {
  changeEventKind: ->
    id = $(this).val()
    app.EventDescription.insertOrAsk(id)

  insertOrAsk: (id) ->
    if this.descriptionEmpty()
      this.fillDescription(id)
    else
      this.enableDefaultLink(id)

  getDescriptionForId: (id) ->
    $('.default-description[data-kind=' + id + ']').text().trim()

  fillDescription: (id) ->
    textarea = this.textarea()
    oldText = textarea.val()
    newText = this.getDescriptionForId(id)

    spacer = if oldText == "" then "" else " "
    textarea.val(oldText + spacer + newText)

  descriptionEmpty: ->
    this.textarea().val() == ""

  insertDescription: (e) ->
    e.preventDefault()
    e.stopPropagation()
    that = app.EventDescription
    id = that.kindSelect().val()
    that.fillDescription(id)
    that.descriptionLink().hide()

  enableDefaultLink: (id) ->
    if id && this.getDescriptionForId(id) != ""
      this.descriptionLink().show()
    else
      this.descriptionLink().hide()

  descriptionLink: ->
    $('.standard-description-link').parents('.help-block')

  textarea: ->
    $('textarea#event_description')

  kindSelect: ->
    $('select#event_kind_id')
}

$(document).on('change', 'select#event_kind_id', app.EventDescription.changeEventKind)
$(document).on('click', '.standard-description-link', app.EventDescription.insertDescription)
$(document).on('turbolinks:load', ->
  $('select#event_kind_id').each((i, e) ->
    app.EventDescription.enableDefaultLink($(e).val())))
