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
#= require jquery_ujs
#= require jquery-ui/datepicker
#= require jquery-ui/effect-highlight
#= require bootstrap-alert
#= require bootstrap-button
#= require bootstrap-dropdown
#= require bootstrap-tooltip
#= require bootstrap-popover
#= require bootstrap-typeahead
#= require jquery_nested_form
#= require jquery-ui-datepicker-i18n
#= require chosen-jquery
#= require remote-typeahead
#= require modernizr.custom.min
#= require_self
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
  track = -> lastDate = $(this).val()

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

resetRolePersonId = (event) ->
  $('#role_person_id').val(null).change()
  $('#role_person').val(null).change()

closePopover = (event) ->
  event.preventDefault()
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
  text = element.data('chosen-no-results') || 'Keine Einträge gefunden mit'
  element.chosen(no_results_text: text,
                 search_contains: true)


Application.updateApplicationMarketCount = ->
  applications = $('tbody#applications tr').size()
  selector = if applications == 1 then 'one' else 'other'
  text = "#{applications} "
  text += $(".pending_applications_info .#{selector}").text()
  $('.pending_applications_info span:eq(0)').html(text)


$ ->
  # wire up quick search
  Application.setupQuicksearch()

  # wire up date picker
  $('body').on('click', 'input.date, .controls .icon-calendar', datepicker.show)

  # wire up elements with ajax replace
  $('body').on('ajax:success','[data-replace]', replaceContent)
  $('body').on('ajax:before','[data-replace]', setDataType)

  # wire up disabled links
  $('body').on('click', 'a.disabled', (event) -> $.rails.stopEverything(event); event.preventDefault();)

  # wire up person auto complete
  $('[data-provide=entity]').each(Application.setupEntityTypeahead)
  $('[data-provide]').each(() -> $(this).attr('autocomplete', "off"))

  # wire up tooltips
  $('body').tooltip({ selector: '[rel=tooltip]', placement: 'right' })

  # set insertFields function for nested-form gem
  window.nestedFormEvents.insertFields = (content, assoc, link) ->
    el = $(link).closest('form').find("##{assoc}_fields")
    el.append($(content))
      .find('[data-provide=entity]').each(Application.setupEntityTypeahead)

  # show alert if ajax requests fail
  $(document).on('ajax:error', (event, xhr, status, error) ->
    alert('Sorry, something went wrong\n(' + error + ')'))

  # make clicking on typeahead item always select it (https://github.com/twitter/bootstrap/issues/4018)
  $('body').on('mousedown', 'ul.typeahead', (e) -> e.preventDefault())

  # control visibilty of group contact fields in relation to contact
  $('body').on('change', '#group_contact_id', toggleGroupContact)

  # enable chosen js
  $('.chosen-select').each(Application.activateChosen)

  # wire up data swap links
  $('body').on('click', 'a[data-swap]', swapElements)

  $('body').on('click', 'a[data-swap="person-fields"]', resetRolePersonId)

  $('body').on('click', '.popover a.cancel', closePopover)

  $('body').on('click', '.filter-toggle', toggleFilterRoles)

