#  Copyright (c) 2023, Carbon. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

app.InvitationLists = {
  updatePath: (e) ->
    event = JSON.parse(e)
    form = $('form#new_event_invitation')[0]
    $("#new_event_invitation button[type='submit']").prop('disabled', false)
    form.action = form.action.replace(/(\d|-)*?(?=\/\w*$)/, event['id'])
    metaToken = $('meta[name=csrf-token]')[0].content
    form.elements['authenticity_token'].value = metaToken
    app.InvitationLists.resetOptions(event.types)
    event.label

  resetOptions: (types) ->
    select = $('#role_type')
    if types.length == 0
      select.hide()
      return

    select.show()
    select.empty()

    $.each types, (_index, type) ->
      select.append $('<option></option>').attr('value', type.name).text(type.label)
      return

}

