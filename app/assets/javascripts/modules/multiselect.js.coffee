#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

app.Multiselect = {
  toggleActions: (e) ->
    table = $('table[data-checkable=true]')
    checked_count = table.find('td input[type=checkbox]:checked').length

    if checked_count > 0
      if table.find('th:hidden').length <= 1
        table.find('thead th:not(:first)').hide()

        table.find('thead tr').append($('.multiselect').clone().fadeIn())
        table.find('thead tr .multiselect').wrap('<th colspan="6">')

      table.find('.multiselect .count').html(checked_count)
    else
      table.find('thead .multiselect').closest('th').remove()
      table.find('thead th:not(:first)').fadeIn()
}

$(document).on('change', 'table[data-checkable=true] input[type=checkbox]', app.Multiselect.toggleActions)
$(document).on('turbolinks:load', ->
  app.Multiselect.toggleActions
)

