app = window.App ||= {}

class app.AjaxUpload
  constructor: (@selector) ->

  submit: (event, input) ->
    $.rails.stopEverything(event)
    form = $(input).closest('form')
    new app.Spinner().show(form)
    form.submit()

  bind: ->
    self = this
    $(document).on('change', @selector, (event) -> self.submit(event, this))

new app.AjaxUpload('form[data-remote] input[type="file"][data-submit]').bind()
