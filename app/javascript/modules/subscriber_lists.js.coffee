#  Copyright (c) 2023, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

app.SubscriberLists = {
  updatePath: (e) ->
    mailingList = JSON.parse(e)
    form = $('form#new_subscription')[0]
    $("#new_subscription button[type='submit']").prop('disabled', false)
    form.action = form.action.replace(/(\d|-)*?(?=\/\w*$)/, mailingList['id'])
    metaToken = $('meta[name=csrf-token]')[0].content
    form.elements['authenticity_token'].value = metaToken
    mailingList.label
}
