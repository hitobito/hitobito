#  Copyright (c) 2015 Pro Natura Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

class app.DatePeriodValidator
  dateFormats = ['YYYY/MM/DD', 'YYYY-MM-DD', 'YYYY.MM.DD', 'D/M/YY', 'D\M\YY',
                 'D-M-YY', 'DD-MM-YYYY', 'D.M.YY', 'D.M.YYYY', 'DD.MM.YYYY', 'D MMM YY']

  constructor: (event) ->
    @_container = $(event.target).closest('.date-period-validated')
    @_fields = $(event.target).closest('.fields')
    @_fields = @_container if @_fields.length == 0

    @_startAtFields = @_findFields(0, 0)
    @_finishAtFields = @_findFields(1, 2)


  validate: ->
    @_clearErrors()

    startAt = @_parseDate(@_startAtFields)
    finishAt = @_parseDate(@_finishAtFields)

    @_validateDate(startAt,
                   @_container.data('start-at-invalid-message'),
                   @_startAtFields)
    @_validateDate(finishAt,
                   @_container.data('finish-at-invalid-message'),
                   @_finishAtFields)

    @_validateDateOrder(startAt, finishAt, @_container.data('before-message'), @_finishAtFields)


  _findFields: (dateOffset, timeOffset) ->
    dateField = $('.date:nth(' + dateOffset + ')', @_fields)
    [dateField,
     $('.time:nth(' + timeOffset + ')', @_fields),
     $('.time:nth(' + (timeOffset + 1) + ')', @_fields),
     dateField.closest('.control-group')]

  _clearErrors: () ->
    @_startAtFields[3].removeClass('error')
    @_finishAtFields[3].removeClass('error')
    $('.help-inline', @_fields).remove()

  _parseDate: (fields) ->
    if fields[0].val().trim()
      moment.utc(fields[0].val().trim(), dateFormats, true).
        set({hour: fields[1].val(), minute: fields[2].val()})

  _validateDate: (date, message, fields) ->
    if date && !date.isValid()
      @_addError(message, fields)

  _validateDateOrder: (startAt, finishAt, message, fields) ->
    if startAt && startAt.isValid() && finishAt && finishAt.isValid() &&
       !startAt.isSame(finishAt) && !startAt.isBefore(finishAt)
      @_addError(message, fields)

  _addError: (message, fields) ->
    lastField = if fields[2].length > 0 then fields[2] else fields[0].parent()
    $('<span class="help-inline">' + message + '</span>').insertAfter(lastField)
    fields[3].addClass('error')



$(document).on('change', '.date-period-validated .date, .date-period-validated .time', (event) ->
  new app.DatePeriodValidator(event).validate())
