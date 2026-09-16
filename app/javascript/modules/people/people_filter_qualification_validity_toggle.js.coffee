#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

$(document).on 'click', 'input[id^=filters_qualification_validity]', () ->
  if (this.value in ['all', 'none', 'only_expired']) && $(this).is(':checked')
    $('input#filters_qualification_match_one').prop('checked', true)
    $('input#filters_qualification_match_all').prop('checked', false).attr('disabled', 'disabled')
    if this.value == 'all'
      $('fieldset#year-scope').show()
      $('fieldset#reference-date').hide()
    if this.value == 'none'
      $('fieldset#year-scope').hide()
      $('fieldset#reference-date').hide()
    if this.value == 'only_expired'
      $('fieldset#year-scope').hide()
      $('fieldset#reference-date').show()

  else
    $('fieldset#year-scope').hide()
    $('fieldset#reference-date').show()
    $('input#filters_qualification_match_all').prop('checked', false).removeAttr('disabled')
