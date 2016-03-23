#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito_dsj and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dsj.

app = window.App ||= {}

app.PersonNotes = {
  addNote: (note) ->
    $('#person-notes-list').prepend(note)
    $('#person-notes-pagination .pagination-info').text('')

    new app.ElementSwapper().swap.call($('#person-notes-form'))
    app.PersonNotes.resetForm()
    app.PersonNotes.hideError()

  resetForm: ->
    $('#person-notes-form').find('form')[0].reset()

  focus: ->
    setTimeout(-> $('#person_note_text').focus())

  showError: (error) ->
    $('#person-notes-error').text(error).show()

  hideError: ->
    $('#person-notes-error').text('').hide()
}

$ ->
  $('#person-notes-new-button').on('click', app.PersonNotes.focus)
  $('#person-notes-form .cancel').on('click', new app.ElementSwapper().swap)
  $('#person-notes-form .cancel').on('click', ->
    app.PersonNotes.resetForm()
    app.PersonNotes.hideError()
  )
