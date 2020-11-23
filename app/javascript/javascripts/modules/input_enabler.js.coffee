#  Copyright (c) 2015 Pro Natura Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

# wire up checkboxes that enable/disable an other element when checked.
class app.InputEnabler
  constructor: (@checkbox) ->

  enable: ->
    selector = $(@checkbox).data('enable')
    $("##{selector}").attr('disabled', !@checkbox.checked && 'disabled')
                     .toggleClass('disabled', !@checkbox.checked);

  disable: ->
    selector = $(@checkbox).data('disable')
    $("##{selector}").attr('disabled', @checkbox.checked && 'disabled')
                     .toggleClass('disabled', @checkbox.checked);


$(document).on('change', 'input[data-disable]', (e) -> new app.InputEnabler(this).disable())
$(document).on('change', 'input[data-enable]', (e) -> new app.InputEnabler(this).enable())

$(document).on('turbolinks:load', ->
  # initialize disabled state of checkbox controlled elements
  $('input[data-disable]').each((index, element) -> new app.InputEnabler(element).disable())
  $('input[data-enable]').each((index, element) -> new app.InputEnabler(element).enable())
)
