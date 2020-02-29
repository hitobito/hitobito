#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

app = window.App ||= {}

app.HelpTextToggler = {
  hideAll: ->
    $('.help-text').hide()
  toggle: (e) ->
    $('.' + $(this).data('key')).slideToggle()
}
app.HelpTextForm = {
  syncSelectFields: ->
    activeContext = $('#help_text_context').val()
    $('.help_text_context_keys').addClass('hidden').find('select').prop("disabled", true)
    $(document.getElementById(activeContext)).removeClass('hidden').find('select').prop("disabled", false)
}

$(document).on 'click', '.help-text-trigger', app.HelpTextToggler.toggle
$(document).on 'change', '#help_text_context', app.HelpTextForm.syncSelectFields

$(document).on 'turbolinks:load', () ->
  app.HelpTextToggler.hideAll()
  app.HelpTextForm.syncSelectFields()
