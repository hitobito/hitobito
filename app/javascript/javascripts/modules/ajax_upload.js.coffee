#  Copyright (c) 2015-2017 Pro Natura Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

class app.AjaxUpload
  constructor: (@selector) ->

  submit: (event, input) ->
    $.rails.stopEverything(event)
    form = $(input).closest('form')
    new app.Spinner().show(form)
    form.submit()
    $(input).closest('form').reset()

  bind: ->
    self = this
    $(document).on('change', @selector, (event) -> self.submit(event, this))

new app.AjaxUpload('form[data-remote] input[type="file"][data-submit]').bind()
