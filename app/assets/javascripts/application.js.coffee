#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# This is a manifest file that'll be compiled into application.js, which will
# include all the files listed below.
#
# Any JavaScript/Coffee file within this directory, lib/assets/javascripts,
# vendor/assets/javascripts, or vendor/assets/javascripts of plugins, if any,
# can be referenced here using a relative path.  It's not advisable to add code
# directly here, but if you do, it'll appear at the bottom of the the compiled
# file.
#
# WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY
# BLANK LINE SHOULD GO AFTER THE REQUIRES BELOW.
#
#= require jquery
#= require jquery.turbolinks
#= require jquery_ujs
#= require jquery-ui/widgets/datepicker
#= require jquery-ui-datepicker-i18n
#= require jquery-ui/effects/effect-highlight
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
#= require modernizr.custom.min
#= require moment.min
#= require_self
#= require_tree ./modules
#= require wagon
#= require turbolinks
#= require progress-bar
#


# scope for global functions
app = window.App ||= {}

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

toggleGroupContact = ->
  open = !$('#group_contact_id').val()
  fields = $('fieldset.info')
  if !open && fields.is(':visible')
    fields.slideUp()
  else if open && !fields.is(':visible')
    fields.slideDown()

toggleFilterRoles = (event) ->
  target = $(event.target)

  boxes = target.nextUntil('.filter-toggle').find(':checkbox')
  checked = boxes.filter(':checked').length == boxes.length

  boxes.each((el) -> $(this).prop('checked', !checked))
  target.data('checked', !checked)

app.activateChosen = (i, element) ->
  element = $(element)
  blank = element.find('option[value]').first().val() == ''
  text = element.data('chosen-no-results') || ' '
  element.chosen({ no_results_text: text, search_contains: true, allow_single_deselect: blank, width: '100%' })



########################################################################
# because of turbolinks.jquery, do bind ALL document events on top level

# wire up elements with ajax replace
$(document).on('ajax:success','[data-replace]', replaceContent)
$(document).on('ajax:before','[data-replace]', setDataType)

# show alert if ajax requests fail
$(document).on('ajax:error', (event, xhr, status, error) ->
  alert('Sorry, something went wrong\n(' + error + ')'))

# wire up disabled links
$(document).on('click', 'a.disabled', (event) -> $.rails.stopEverything(event); event.preventDefault();)

# make clicking on typeahead item always select it (https://github.com/twitter/bootstrap/issues/4018)
$(document).on('mousedown', 'ul.typeahead', (e) -> e.preventDefault())

# control visibilty of group contact fields in relation to contact
$(document).on('change', '#group_contact_id', toggleGroupContact)

$(document).on('click', '.filter-toggle', toggleFilterRoles)

# only bind events for non-document elements in $ ->
$ ->

  # wire up tooltips
  $(document).tooltip({ selector: '[rel^=tooltip]', placement: 'right' })

  # enable chosen js
  $('.chosen-select').each(app.activateChosen)
