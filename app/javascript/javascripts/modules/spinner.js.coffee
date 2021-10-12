#  Copyright (c) 2015 Pro Natura Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

# Shows/hides a spinner when a button triggers an ajax request.
class app.Spinner

  show: (button, spinnerSelector) ->
    $(button).
      prop('disable', true).
      addClass('disabled')
    this.findSpinner($(button), spinnerSelector).show()

  hide: (button, spinnerSelector) ->
    $(button).
      prop('disable', false).
      removeClass('disabled')
    this.findSpinner($(button), spinnerSelector).hide()

  findSpinner: (button, selector) ->
    if selector then $(selector) else button.siblings('.spinner')

  bind: ->
    self = this
    $(document).on('ajax:beforeSend', '[data-spin]', (e) -> self.show(this, $(e.target).data('spin')))
    $(document).on('ajax:complete', '[data-spin]', (e) -> self.hide(this, $(e.target).data('spin')))


new app.Spinner().bind()
