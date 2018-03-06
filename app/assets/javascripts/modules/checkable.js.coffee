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

$(document).on('submit', 'form[data-checkable]', (e) ->
  ids = ($(item).val() for item in  $('table[data-checkable] tbody :checked'))
  $(this).find('input:input[data-checkable]').val(ids)
)

buildLinkWithIds = (href) ->
  ids = ($(item).val() for item in  $('table[data-checkable] tbody :checked'))
  separator = if href.indexOf('?') != -1 then '&' else '?'
  match = window.location.href.match(/.+?\/(\d+)$/)
  if match
    href + separator + "ids=#{[match[1]]}&singular=true"
  else
    href + separator + "ids=#{ids}"

$.rails.href = (element) ->
  href = element[0].href
  if $(element).is('a[data-checkable]') then buildLinkWithIds(href) else href
