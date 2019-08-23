#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

app = window.App ||= {}

app.FieldHelpTextToggler = {
  currentlyHidden: true

  toggle: ->
    app.FieldHelpTextToggler.currentlyHidden = !app.FieldHelpTextToggler.currentlyHidden
    app.FieldHelpTextToggler.applyCurrentState()

  applyCurrentState: ->
    hideButton = $('#hideFieldHelpTexts')
    showButton = $('#showFieldHelpTexts')
    texts = $('.additional_help_text')

    if app.FieldHelpTextToggler.currentlyHidden
      hideButton.hide()
      showButton.show()
      texts.slideUp()
    else
      hideButton.show()
      showButton.hide()
      texts.slideDown()
}

handleSilently = (f) -> (e) -> e.preventDefault(); f()

$(document).on('turbolinks:load', app.FieldHelpTextToggler.applyCurrentState)
$(document).on('click', '#showFieldHelpTexts, #hideFieldHelpTexts', handleSilently(app.FieldHelpTextToggler.toggle))
