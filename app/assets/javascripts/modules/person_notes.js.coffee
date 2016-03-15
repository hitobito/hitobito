#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito_dsj and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dsj.

app = window.App ||= {}

app.PersonNotes = {
  showForm: ->
    form = $('#person-notes-form')
    form.slideDown(undefined, -> $('#person_note_text').focus())

    button = $('#person-notes-new-button')
    button.hide()

  cancelForm: ->
    form = $('#person-notes-form')
    form.find('form')[0].reset()
    form.slideUp()

    button = $('#person-notes-new-button')
    button.show()

    # explicitly return undefined to work with href="javascript:..." links
    return
}
