#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito_dsj and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dsj.

app = window.App ||= {}

app.PersonNotes = {
  showForm: ->
    form = $('#person-notes-form')
    form.slideDown(undefined, -> $('#person_note_text').focus())

    $('#person-notes-new-button').hide()
    $('#person-notes-error').text('').hide()

  hideForm: ->
    form = $('#person-notes-form')
    form.find('form')[0].reset()
    form.slideUp()

    $('#person-notes-new-button').show()
    $('#person-notes-error').text('').hide()

    # explicitly return undefined to work with href="javascript:..." links
    return

  addNote: (note) ->
    $('#person-notes-list').prepend(note)

  showError: (error) ->
    $('#person-notes-error').text(error).show()
}
