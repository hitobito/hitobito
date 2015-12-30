#  Copyright (c) 2015 Pro Natura Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

class app.EventDateValidator
  constructor: ->
    @eventDateFormats = ['YYYY/MM/DD', 'YYYY-MM-DD', 'YYYY.MM.DD', 'D/M/YY', 'D\M\YY',
                        'D-M-YY', 'DD-MM-YYYY', 'D.M.YY', 'D.M.YYYY', 'DD.MM.YYYY', 'D MMM YY']

  validateEventDatesFields: (event) ->
    fieldSet = $(event.target).closest('fieldset')
    fields = $(event.target).closest('.fields')
    startAtDateField = $('.date:nth(0)', fields)
    startAtHourField = $('.time:nth(0)', fields)
    startAtMinField = $('.time:nth(1)', fields)
    startAtGroup = startAtDateField.closest('.control-group')
    startAt = null
    finishAtDateField = $('.date:nth(1)', fields)
    finishAtHourField = $('.time:nth(2)', fields)
    finishAtMinField = $('.time:nth(3)', fields)
    finishAtGroup = finishAtDateField.closest('.control-group')
    finishAt = null

    startAtGroup.removeClass('error')
    finishAtGroup.removeClass('error')
    $('.help-inline', fields).remove()

    if startAtDateField.val().trim()
      startAt = moment.utc(startAtDateField.val().trim(), @eventDateFormats, true).
        set({hour: startAtHourField.val(), minute: startAtMinField.val()})
      if !startAt.isValid()
        # invalid start date
        $('<span class="help-inline">' + fieldSet.data('start-at-invalid-message') + '</span>').insertAfter(startAtMinField)
        startAtGroup.addClass('error')

    if finishAtDateField.val().trim()
      finishAt = moment.utc(finishAtDateField.val().trim(), @eventDateFormats, true).
        set({hour: finishAtHourField.val(), minute: finishAtMinField.val()})
      if !finishAt.isValid()
        # invalid finish date
        $('<span class="help-inline">' + fieldSet.data('finish-at-invalid-message') + '</span>').insertAfter(finishAtMinField)
        finishAtGroup.addClass('error')

    if startAt && startAt.isValid() && finishAt && finishAt.isValid() &&
       !startAt.isSame(finishAt) && !startAt.isBefore(finishAt)
      # finish date is before start date
      $('<span class="help-inline">' + fieldSet.data('before-message') + '</span>').insertAfter(finishAtMinField)
      finishAtGroup.addClass('error')

  bind: ->
    self = this
    $('.event-dates').on('change', '.date, .time', (event) -> self.validateEventDatesFields(event))

# only bind events for non-document elements in $ ->
$ ->
  new app.EventDateValidator().bind()
