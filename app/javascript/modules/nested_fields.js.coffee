$(document).on 'nested:fieldRemoved', (event) ->
  $('[required]', event.field).removeAttr('required')
