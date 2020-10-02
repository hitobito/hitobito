$(document).on('turbolinks:load', ->
  $('.collapse').on 'shown', (event) ->
    event.target.classList.add 'visible'
    return

  $('.collapse').on 'hide', (event) ->
    event.target.classList.remove 'visible'
    return
)