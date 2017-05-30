#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

# wire up links/buttons that swap with another element when clicked.
class app.ElementSwapper
  swap: (event) ->
    selector = $(this).data('swap')

    if !selector
      # if not on element itself, look upwards for 'swap' data attribute
      selector = $(this).closest('[data-swap]').data('swap')

    $('.' + selector).slideToggle()

    if event
      event.preventDefault()

  resetRolePersonId: (event) ->
    $('#role_person_id').val(null).change()
    $('#role_person').val(null).change()
    event.preventDefault()

$(document).on('click', 'a[data-swap], button[data-swap]', new app.ElementSwapper().swap)

# additional custom swap actions
$(document).on('click', 'a[data-swap="person-fields"]', new app.ElementSwapper().resetRolePersonId)
