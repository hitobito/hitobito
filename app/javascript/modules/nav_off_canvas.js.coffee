#  Copyright (c) 2018, hitobito AG. This file is part of
#  hitobito_dsj and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

app.NavOffCanvas = {
  toggle: (e) ->
    e.preventDefault()
    $('.nav-left').toggleClass("is-visible")
}

$(document).on('click', '.toggle-nav', app.NavOffCanvas.toggle)
$(document).on('click', '.nav-left-overlay', app.NavOffCanvas.toggle)
$(document).keyup (e) ->
  if (e.key == 'Escape') && $('.nav-left').hasClass('is-visible')
    app.NavOffCanvas.toggle(e)