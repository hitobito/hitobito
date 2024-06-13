#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# control visibilty of group contact fields in relation to contact

toggleGroupContact = ->
  open = !$('#group_contact_id').val()
  fields = $('fieldset.info')
  if !open && fields.is(':visible')
    fields.slideUp()
  else if open && !fields.is(':visible')
    fields.slideDown()

$(document).on('change', '#group_contact_id', toggleGroupContact)
