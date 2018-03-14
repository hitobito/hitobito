#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

$(document).on 'click', 'input[id^=filters_qualification_validity]', () ->
  if this.value == 'all' && $(this).is(':checked')
    $('input#match_one').prop('checked', true)
    $('input#match_all').prop('checked', false).attr('disabled', 'disabled')
    $('fieldset#year-scope').show()
  else
    $('fieldset#year-scope').hide()
    $('input#match_all').prop('checked', false).removeAttr('disabled')
