#  Copyright (c) 2015 Pro Natura Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

# Shows/hides a spinner when a button triggers an ajax request.
class app.Spinner

  show: (button) ->
    $(button).
      prop('disable', true).
      addClass('disabled').
      siblings('.spinner').show()

  hide: (button) ->
    $(button).
      prop('disable', false).
      removeClass('disabled').
      siblings('.spinner').hide()

  bind: ->
    self = this
    $(document).on('ajax:beforeSend', '[data-spin]', () -> self.show(this))
    $(document).on('ajax:complete', '[data-spin]', () -> self.hide(this))


new app.Spinner().bind()
