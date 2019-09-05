#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

app = window.App ||= {}

app.FieldHelpTextToggler = {
  hideAll: ->
    $('.controls .help-text').hide()
  toggle: (e) ->
    $(this).parents('.controls').find('.help-text').slideToggle()
}

$(document).on('turbolinks:load', app.FieldHelpTextToggler.hideAll)
$(document).on('click', '.help-text-trigger', app.FieldHelpTextToggler.toggle)
