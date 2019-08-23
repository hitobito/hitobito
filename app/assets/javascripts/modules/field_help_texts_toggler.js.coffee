#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

app = window.App ||= {}

app.FieldHelpTextToggler = {
  init: ->
    app.FieldHelpTextToggler.hide()
  show: ->
    $('#hideFieldHelpTexts').show()
    $('#showFieldHelpTexts').hide()
    $('.additional_help_text').slideDown()
  hide: ->
    $('#hideFieldHelpTexts').hide()
    $('#showFieldHelpTexts').show()
    $('.additional_help_text').slideUp()
}

handleSilently = (f) -> (e) -> e.preventDefault(); f()

$ -> app.FieldHelpTextToggler.init()
$(document).on('click', '#showFieldHelpTexts', handleSilently(app.FieldHelpTextToggler.show))
$(document).on('click', '#hideFieldHelpTexts', handleSilently(app.FieldHelpTextToggler.hide))
