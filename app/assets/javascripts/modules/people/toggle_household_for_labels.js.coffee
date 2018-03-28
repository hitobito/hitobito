#  Copyright (c) 2015 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

$(document).on('click', '#toggle-household-labels', (event) ->
  event.stopPropagation()
  $(this).find('input[type="checkbox"]').toggle
)

$(document).on('change', '#toggle-household-labels input[type="checkbox"]', () ->
  param = 'household='
  checked = !!this.checked
  $(this).parents('.dropdown-menu').find('a.export-label-format').each ->
    $(this).attr('href', $(this).attr('href').replace(param + !checked, param + checked))  
)
