#  Copyright (c) 2015 Pro Natura Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

# wire up checkboxes that enable/disable an other element when checked.
class app.PopoverHandler
  constructor: () ->

  toggle: (toggler, event) ->
    # custom code to close other popovers when a new one is opened
    $('[data-toggle=popover]').not(toggler).popover('hide')
    $(toggler).popover()
    popover = $(toggler).data('popover')
    popover.options.html = true
    popover.options.placement = 'bottom'
    event.preventDefault()
    if popover.tip().hasClass('fade') && !popover.tip().hasClass('in')
      $(toggler).popover('hide')
    else
      $(toggler).popover('show')

  close: (event) ->
    event.preventDefault()
    $('[data-toggle=popover]').popover('hide')
    $($('body').data('popover')).popover('destroy')

  bind: ->
    self = this
    $(document).on('click', '[data-toggle=popover]', (e) -> self.toggle(this, e))
    $(document).on('click', '.popover a.cancel', (e) -> self.close(e))

new app.PopoverHandler().bind()
