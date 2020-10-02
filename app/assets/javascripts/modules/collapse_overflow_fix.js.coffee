$(document).on('turbolinks:load', ->
  $('.collapse').on 'shown', (event) ->
    event.target.classList.add 'shown'
    return

  $('.collapse').on 'hide', (event) ->
    event.target.classList.remove 'shown'
    return
)