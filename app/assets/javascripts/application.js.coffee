#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# This is a manifest file that'll be compiled into application.js, which will include all the files
# listed below.
#
# Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
# or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# the compiled file.
#
# WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
# GO AFTER THE REQUIRES BELOW.
#
#= require jquery
#= require jquery.turbolinks
#= require jquery_ujs
#= require jquery-ui/datepicker
#= require jquery-ui-datepicker-i18n
#= require jquery-ui/effect-highlight
#= require bootstrap-alert
#= require bootstrap-button
#= require bootstrap-dropdown
#= require bootstrap-tooltip
#= require bootstrap-popover
#= require bootstrap-typeahead
#= require bootstrap-tab
#= require jquery_nested_form
#= require chosen-jquery
#= require jquery.remotipart
#= require remote-typeahead
#= require modernizr.custom.min
#= require moment.min
#= require_self
#= require_tree ./modules
#= require wagon
#= require turbolinks
#= require progress-bar
#


# scope for global functions
window.Application ||= {}

# add trim function for older browsers
if !String.prototype.trim
  String.prototype.trim = () -> this.replace(/^\s+|\s+$/g, '')


replaceContent = (e, data, status, xhr) ->
  replace = $(this).data('replace')
  el = if replace is true then $(this).closest('form') else $("##{replace}")
  console.warn "found no element to replace" if el.size() is 0
  el.html(data)

setDataType = (xhr) ->
  $(this).data('type', 'html')

# start selection on previously selected date
datepicker = do ->
  lastDate = null
  track = (d, i) ->
    lastDate = $(this).val()

    if d isnt i.lastVal
      $(this).change()

  show: ->
    field = $(this)
    if field.is('.icon-calendar')
      field = field.parent().siblings('.date')
    options = $.extend({onSelect: track}, $.datepicker.regional[$('html').attr('lang')])
    field.datepicker(options)
    field.datepicker('show')

    if lastDate && field.val() is ""
      field.datepicker('setDate', lastDate)
      field.val('') # user must confirm selection

toggleGroupContact = ->
  open = !$('#group_contact_id').val()
  fields = $('fieldset.info')
  if !open && fields.is(':visible')
    fields.slideUp()
  else if open && !fields.is(':visible')
    fields.slideDown()

swapElements = (event) ->
  css = $(this).data('swap')
  $('.' + css).slideToggle()
  event.preventDefault()

toggleElementByLink = (event) ->
  selector = $(this).data('hide')
  if $("##{selector}").is(':visible')
    $("##{selector}").slideUp()
  else
    $("##{selector}").slideDown()
  event.preventDefault()

hideElementByCheckbox = ->
  selector = $(this).data('hide')
  if this.checked
    $("##{selector}").slideUp()
  else
    $("##{selector}").slideDown()

showElementByCheckbox = ->
  selector = $(this).data('show')
  if this.checked
    $("##{selector}").slideDown()
  else
    $("##{selector}").slideUp()

disableElementByCheckbox = ->
  selector = $(this).data('disable')
  $("##{selector}").attr('disabled', this.checked && 'disabled')
                   .toggleClass('disabled', this.checked);

enableElementByCheckbox = ->
  selector = $(this).data('enable')
  $("##{selector}").attr('disabled', !this.checked && 'disabled')
                   .toggleClass('disabled', !this.checked);

resetRolePersonId = (event) ->
  $('#role_person_id').val(null).change()
  $('#role_person').val(null).change()

togglePopover = (event) ->
  # custom code to close other popovers when a new one is opened
  $('[data-toggle=popover]').not(this).popover('hide')
  $(this).popover()
  popover = $(this).data('popover')
  popover.options.html = true
  popover.options.placement = 'bottom'
  if popover.tip().hasClass('fade') && !popover.tip().hasClass('in')
    $(this).popover('hide')
  else
    $(this).popover('show')

closePopover = (event) ->
  event.preventDefault()
  $('[data-toggle=popover]').popover('hide')
  $($('body').data('popover')).popover('destroy')

toggleFilterRoles = (event) ->
  target = $(event.target)

  boxes = target.nextUntil('.filter-toggle').find(':checkbox')
  checked = boxes.filter(':checked').length == boxes.length

  boxes.each((el) -> $(this).prop('checked', !checked))
  target.data('checked', !checked)

Application.moveElementToBottom = (elementId, targetId, callback) ->
  $target = $('#' + targetId)
  left = $target.offset().left
  top = $target.offset().top + $target.height()
  $element = $('#' + elementId)
  leftOld = $element.offset().left
  topOld = $element.offset().top
  $element.children().each((i, c) -> $c = $(c); $c.css('width', $c.width()))
  $element.css('left', leftOld)
  $element.css('top', topOld)
  $element.css('position', 'absolute')
  $element.animate({left: left, top: top}, 300, callback)

Application.activateChosen = (i, element) ->
  element = $(element)
  blank = element.find('option[value]').first().val() == ''
  text = element.data('chosen-no-results') || ' '
  element.chosen({ no_results_text: text, search_contains: true, allow_single_deselect: blank, width: '100%' })

Application.updateApplicationMarketCount = ->
  applications = $('tbody#applications tr').size()
  selector = if applications == 1 then 'one' else 'other'
  text = "#{applications} "
  text += $(".pending_applications_info .#{selector}").text()
  $('.pending_applications_info span:eq(0)').html(text)


eventDateFormats = ['YYYY/MM/DD', 'YYYY-MM-DD', 'YYYY.MM.DD', 'D/M/YY', 'D\M\YY',
                    'D-M-YY', 'DD-MM-YYYY', 'D.M.YY', 'D.M.YYYY', 'DD.MM.YYYY', 'D MMM YY']
validateEventDatesFields = (event) ->
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
    startAt = moment.utc(startAtDateField.val().trim(), eventDateFormats, true).
      set({hour: startAtHourField.val(), minute: startAtMinField.val()})
    if !startAt.isValid()
      # invalid start date
      $('<span class="help-inline">' + fieldSet.data('start-at-invalid-message') + '</span>').insertAfter(startAtMinField)
      startAtGroup.addClass('error')

  if finishAtDateField.val().trim()
    finishAt = moment.utc(finishAtDateField.val().trim(), eventDateFormats, true).
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


# set insertFields function for nested-form gem
window.nestedFormEvents.insertFields = (content, assoc, link) ->
  el = $(link).closest('form').find("##{assoc}_fields")
  el.append($(content))
  .find('[data-provide=entity]').each(Application.setupEntityTypeahead)


########################################################################
# because of turbolinks.jquery, do bind ALL document events on top level

# wire up date picker
$(document).on('click', 'input.date, .controls .icon-calendar', datepicker.show)

# wire up elements with ajax replace
$(document).on('ajax:success','[data-replace]', replaceContent)
$(document).on('ajax:before','[data-replace]', setDataType)

# wire up disabled links
$(document).on('click', 'a.disabled', (event) -> $.rails.stopEverything(event); event.preventDefault();)

# wire up popovers
$(document).on('click', '[data-toggle=popover]', togglePopover)

# show alert if ajax requests fail
$(document).on('ajax:error', (event, xhr, status, error) ->
  alert('Sorry, something went wrong\n(' + error + ')'))

# make clicking on typeahead item always select it (https://github.com/twitter/bootstrap/issues/4018)
$(document).on('mousedown', 'ul.typeahead', (e) -> e.preventDefault())

# control visibilty of group contact fields in relation to contact
$(document).on('change', '#group_contact_id', toggleGroupContact)

# wire up links that hide an other element when checked.
$(document).on('click', 'a[data-hide]', toggleElementByLink)

# wire up checkboxes that hide an other element when checked.
$(document).on('change', 'input[data-hide]', hideElementByCheckbox)

# wire up checkboxes that show an other element when checked.
$(document).on('change', 'input[data-show]', showElementByCheckbox)

# wire up checkboxes that disable an other element when checked.
$(document).on('change', 'input[data-disable]', disableElementByCheckbox)

# wire up checkboxes that enable an other element when checked.
$(document).on('change', 'input[data-enable]', enableElementByCheckbox)

$(document).on('click', 'a[data-swap="person-fields"]', resetRolePersonId)

$(document).on('click', '.popover a.cancel', closePopover)

$(document).on('click', '.filter-toggle', toggleFilterRoles)

# wire up data swap links
$(document).on('click', 'a[data-swap]', swapElements)


# only bind events for non-document elements in $ ->
$ ->
  # wire up quick search
  Application.setupQuicksearch()

  # wire up person auto complete
  $('[data-provide=entity]').each(Application.setupEntityTypeahead)
  $('[data-provide]').each(() -> $(this).attr('autocomplete', "off"))

  # wire up tooltips
  $(document).tooltip({ selector: '[rel^=tooltip]', placement: 'right' })

  # enable chosen js
  $('.chosen-select').each(Application.activateChosen)

  # wire up client-side validation of event dates
  $('.event-dates').on('change', '.date, .time', validateEventDatesFields)

  # initialize visibility and disabled state of checkbox controlled elements
  $('input[data-hide]').each((index, element) -> hideElementByCheckbox.call(element))
  $('input[data-show]').each((index, element) -> showElementByCheckbox.call(element))
  $('input[data-disable]').each((index, element) -> disableElementByCheckbox.call(element))
  $('input[data-enable]').each((index, element) -> enableElementByCheckbox.call(element))
