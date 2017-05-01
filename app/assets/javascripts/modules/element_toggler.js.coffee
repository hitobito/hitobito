#  Copyright (c) 2015 Pro Natura Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

# wire up checkboxes that show/hide an other element when checked.
class app.ElementToggler
  constructor: (@checkbox) ->

  hide: ->
    selector = $(@checkbox).data('hide')
    if @checkbox.checked
      $("##{selector}").slideUp()
    else
      $("##{selector}").slideDown()

  show: ->
    selector = $(@checkbox).data('show')
    if @checkbox.checked
      $("##{selector}").slideDown()
    else
      $("##{selector}").slideUp()

  toggle: (event) ->
    selector = $(@checkbox).data('hide')
    if $("##{selector}").is(':visible')
      $("##{selector}").slideUp()
    else
      $("##{selector}").slideDown()
    event.preventDefault()

$(document).on('change', 'input[data-hide]', (e) -> new app.ElementToggler(this).hide())
$(document).on('change', 'input[data-show]', (e) -> new app.ElementToggler(this).show())
$(document).on('click', 'a[data-hide]', (e) -> new app.ElementToggler(this).toggle(e))

$(document).on('turbolinks:load', ->
  # initialize visibility of checkbox controlled elements
  $('input[data-hide]').each((index, element) -> new app.ElementToggler(element).hide())
  $('input[data-show]').each((index, element) -> new app.ElementToggler(element).show())
)
