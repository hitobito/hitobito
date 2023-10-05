#  Copyright (c) 2015 Pro Natura Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

# wire up checkboxes that enable/disable an other element when checked.
class app.PopoverHandler
  constructor: () ->

  toggle: (event) ->
    $(event.target).popover({
      content: event.target.dataset.bsContent,
      title: event.target.dataset.bsTitle,
      container: 'body',
      placement: 'bottom',
      trigger: 'click',
      sanitize: false,
      html: true
    }).popover('show');
    $(document).trigger('popoverOpened');


  close: (event) ->
    setTimeout ->
      $('[data-bs-toggle=popover]').popover('hide')
      $($('body').data('popover')).popover('destroy')
    , 100

  bind: ->
    self = this
    $(document).on('click', '[data-bs-toggle=popover]', (e) -> self.toggle(e))
    $(document).on('click', '.popover a.cancel', (e) -> self.close(e))
    $(document).on('click', '.popover button:submit', (e) -> self.close(e))

new app.PopoverHandler().bind()
