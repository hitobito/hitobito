- #  Copyright (c) 2012-2021, Pfadibewegung Schweiz. This file is part of
- #  hitobito and licensed under the Affero General Public License version 3
- #  or later. See the COPYING file at the top-level directory or at
- #  https://github.com/hitobito/hitobito.

app = window.App ||= {}

app.Events = {
  contactChanged: (e) ->
    checkbox = notificationCheckbox(e.target)
    row = notificationRow(checkbox)
    if hasContact(e.target)
      row.show()
    else
      checkbox.prop('checked', false)
      row.hide()
}

hasContact = (input) -> $(input).val().trim() != ""
notificationCheckbox = (input) ->
    $(input).closest('form')
        .find('input[type="checkbox"][name="event[notify_contact_on_participations]"]')
notificationRow = (checkbox) -> checkbox.closest('.display-wrapper')

$(document).on('change', 'input#event_contact', app.Events.contactChanged)
