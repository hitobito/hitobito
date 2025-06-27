#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

$(document).on 'change', 'select#qualification-validity-select', () ->
  value = $(this).val()
  if value in ['all', 'none', 'only_expired']
    $('input#filters_qualification_match_one').prop('checked', true)
    $('input#filters_qualification_match_all').prop('checked', false).attr('disabled', 'disabled')
    if this.value == 'all'
      $('div#year-scope').show()
      $('div#reference-date').hide()
    if this.value == 'none'
      $('div#year-scope').hide()
      $('div#reference-date').hide()
    if this.value == 'only_expired'
      $('div#year-scope').hide()
      $('div#reference-date').show()

  else
    $('div#year-scope').hide()
    $('div#reference-date').show()
    $('input#filters_qualification_match_all').prop('checked', false).removeAttr('disabled')
