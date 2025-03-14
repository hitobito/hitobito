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

    # yearRange defines what years are selectable in the dropdown.
    # either relative to today's year ("-nn:+nn"), relative to the currently selected
    # year ("c-nn:c+nn"), absolute ("nnnn:nnnn").
    yearRange = if input.attributes.yearRange? then input.attributes.yearRange.value else $.datepicker._defaults.yearRange
    minDate = if input.attributes.mindate? then new Date(input.attributes.mindate.value) else null
    maxDate = if input.attributes.maxdate? then new Date(input.attributes.maxdate.value) else null

    # Try to find the better matching fr-CH and it-CH
    lang = $('html').attr('lang')
    lang_ch = lang + '-CH'
    options = $.extend({ onSelect: (d, i) -> self.track(this, d, i) },
#      $.datepicker.regional[lang_ch] || $.datepicker.regional[lang],

      $.datepicker.regional[lang_ch] || $.datepicker.regional['de'],      

      minDate: minDate,
      maxDate: maxDate,
      changeMonth: true,
      changeYear: true,
      yearRange: yearRange,
    )

    field.datepicker(options)
    field.datepicker('show')

    if @lastDate && field.val() is ""
      field.datepicker('setDate', @lastDate)
      field.val('') # user must confirm selection

  bind: ->
    self = this
    $(document).on('click', 'input.date, .control-group .icon-calendar', (e) -> self.show(this))

new app.Datepicker().bind()
