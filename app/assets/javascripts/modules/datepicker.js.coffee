#  Copyright (c) 2015 Pro Natura Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

# start selection on previously selected date
class app.Datepicker
  constructor: ->
    @lastDate = null

  track: (input, d, i) ->
    @lastDate = $(input).val()

    if d isnt i.lastVal
      $(input).change()

  show: (input) ->
    self = this
    field = $(input)
    if field.is('.icon-calendar')
      field = field.parent().siblings('.date')
    options = $.extend({ onSelect: (d, i) -> self.track(this, d, i) }, $.datepicker.regional[$('html').attr('lang')])
    field.datepicker(options)
    field.datepicker('show')

    if @lastDate && field.val() is ""
      field.datepicker('setDate', @lastDate)
      field.val('') # user must confirm selection

  bind: ->
    self = this
    $(document).on('click', 'input.date, .control-group .icon-calendar', (e) -> self.show(this))

new app.Datepicker().bind()
