class ClearInput

  clear: (cross) ->
    @_input(cross).val('').trigger('change')

  toggleHide: (input) ->
    group = input.parents('.control-group')
    if input.val() == ''
      group.addClass('has-empty-value')
    else
      group.removeClass('has-empty-value')

  _input: (cross) ->
    cross.parents('.control-group').find('input')

  bind: ->
    self = this
    $(document).on('click', '[data-clear]', () -> self.clear($(this)))
    $(document).on('change', '.has-clear input', () -> self.toggleHide($(this)))


new ClearInput().bind()

$(document).on 'turbolinks:load', ->
  $('.has-clear input').each((i, e) -> new ClearInput().toggleHide($(e)))
