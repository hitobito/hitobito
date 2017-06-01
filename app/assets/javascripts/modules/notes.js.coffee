#  Copyright (c) 2012-2017, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

app.Notes = {
  addNote: (note) ->
    $('#notes-list').prepend(note)
    $('#notes-list .pagination-info').text('')

    new app.ElementSwapper().swap.call($('#notes-form'))
    app.Notes.resetForm()
    app.Notes.hideError()

  resetForm: ->
    $('#notes-form').find('form')[0].reset()

  focus: ->
    setTimeout(-> $('#note_text').focus())

  showError: (error) ->
    $('#notes-error').text(error).show()

  hideError: ->
    $('#notes-error').text('').hide()
}


$(document).on('turbolinks:load', ->
  $('#notes-new-button').on('click', app.Notes.focus)
  $('#notes-form .cancel').on('click', new app.ElementSwapper().swap)
  $('#notes-form .cancel').on('click', ->
    app.Notes.resetForm()
    app.Notes.hideError()
  )
)
