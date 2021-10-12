# trigger remote elements on page load

$(document).on('turbolinks:load', ->
  document.querySelectorAll('[data-remote][data-on-page-load]').forEach (elem) ->
    $.rails.handleRemote($(elem))
)
