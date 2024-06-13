$(document).on 'click', 'a[data-copy-to-clipboard]', (e) ->
  e.preventDefault()
  text = e.target.getAttribute('data-copy-to-clipboard')
  el = $("<input type='text' value='#{text}'/>")
  $('body').append(el)
  el.select()
  document.execCommand("copy")
  el.remove()
