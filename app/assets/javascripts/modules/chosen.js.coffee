#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# scope for global functions
app = window.App ||= {}

app.activateChosen = (i, element) ->
  element = $(element)
  blank = element.find('option[value]').first().val() == ''
  text = element.data('chosen-no-results') || ' '
  element.chosen({
    no_results_text: text,
    search_contains: true,
    allow_single_deselect: blank,
    width: '100%' })

# only bind events for non-document elements in turbolinks:load
$(document).on('turbolinks:load', ->
  # enable chosen js
  $('.chosen-select').each(app.activateChosen)
)
