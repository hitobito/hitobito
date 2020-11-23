$(document).on('turbolinks:load', ->
  $('.collapse.in').addClass('shown')

  $('.collapse').on 'shown', () ->
    $(this).addClass('shown')
    return

  $('.collapse').on 'hide', () ->
    $(this).removeClass('shown')
    return
)