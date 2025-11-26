#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

app.Taggable = {
  showForm: ->
    $('.taggable-add-form').show();
    $('.taggable-add-form input#acts_as_taggable_on_tag_name').val('').focus()
    $('.tag-add').hide();

  hideForm: ->
    $('.taggable-add-form').hide();
    $('.tag-add').show();
    app.Taggable.loading(false)

  loading: (flag) ->
    $('.taggable-add-form .error-message').hide()
    $('.taggable-add-form button').prop('disabled', flag)
    $('.taggable-add-form button .spinner').toggle(flag);

  loadError: (event, xhr, status) ->
    app.Taggable.loading(false)
    if (xhr.status == 403)
      event.stopPropagation()
      event.preventDefault()
      $('.taggable-add-form .error-message').show()

  updateTags: (tags) ->
    $('.tags').replaceWith(tags)
    app.Taggable.hideForm()
    $('.tag-add').focus();

  removeTag: (event) ->
    event.preventDefault()
    tagId = $(event.target).parent().data('tag-id')
    $('.tags').find('.tag').each((i, elem) ->
      tag = $(elem)
      if tag.data('tag-id') == tagId
        if tag.parent().children().length == 1
          tag.closest('.taggable-category').remove()
          return false
        else
          tag.remove()
          return false
    )
}

$(document).on('click', 'a.tag-remove', app.Taggable.removeTag)
$(document).on('click', '.tag-add', app.Taggable.showForm)
$(document).on('submit', '.taggable-add-form', -> app.Taggable.loading(true); return true);
$(document).on('ajax:error', '.taggable-add-form', (event, xhr, status) -> app.Taggable.loadError(event, xhr, status));
$(document).on('keydown', '.taggable-add-form input#acts_as_taggable_on_tag_name', (event) ->
    event.keyCode == 27 && app.Taggable.hideForm(); return true)
