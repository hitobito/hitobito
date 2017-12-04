#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

$(document).on('click', 'table[data-checkable] thead :checkbox', (e) ->
  checked = e.target.checked
  table = $(e.target).closest('table[data-checkable]')
  table.find('tbody :checkbox').prop('checked', checked)
)

$(document).on('click', 'a[data-checkable]:not(data-method)', (e) ->
  e.target.href = buildLinkWithIds(e.target.href)
)

buildLinkWithIds = (href) ->
  ids = ($(item).val() for item in  $('table[data-checkable] tbody :checked'))
  separator = if href.indexOf('?') != -1 then '&' else '?'
  href + separator + "ids=#{ids}"

$.rails.href = (element) ->
  href = element[0].href
  if $(element).is('a[data-checkable]') then buildLinkWithIds(href) else href
