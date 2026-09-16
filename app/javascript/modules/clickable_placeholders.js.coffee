$(document).on 'click', 'a[data-clickable-placeholder]', (e) ->
  e.preventDefault()
  editor_id = e.target.getAttribute('data-clickable-placeholder')
  placeholder = e.target.textContent
  $("##{editor_id}").get(0).editor.insertString(placeholder)
