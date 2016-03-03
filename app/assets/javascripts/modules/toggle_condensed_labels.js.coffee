#  Copyright (c) 2015 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

$ ->
  button = $('#toggle-condense-labels')
  checkbox = button.find('input[type="checkbox"]')
  param = 'condense_labels='

  button.click (event) ->
    event.stopPropagation()
    checkbox.toggle

  checkbox.change ->
    checked = !!this.checked
    $(this).parents('.dropdown-menu').find('a.export-label-format').each ->
      $(this).attr('href', $(this).attr('href').replace(param + !checked, param + checked))
