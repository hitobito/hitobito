# set focus on newly added field
$(document).on 'nested:fieldAdded', (event) ->
  event.field.find('div.fields:last-child > div.controls > input[type!="hidden"]:first').focus()
