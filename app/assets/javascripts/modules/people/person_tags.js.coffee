#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

app.PersonTags = {
  showForm: ->
    $('.person-tags-add-form').show();
    $('.person-tags-add-form input#acts_as_taggable_on_tag_name').val('').focus()
    $('.person-tag-add').hide();

  hideForm: ->
    $('.person-tags-add-form').hide();
    $('.person-tag-add').show();
    app.PersonTags.loading(false)

  loading: (flag) ->
    $('.person-tags-add-form button').prop('disabled', flag)
    $('.person-tags-add-form button .spinner').toggle(flag);

  updateTags: (tags) ->
    $('.person-tags').replaceWith(tags)
    app.PersonTags.hideForm()
    $('.person-tag-add').focus();

  removeTag: (event) ->
    event.preventDefault()
    tagId = $(event.target).parent().data('tag-id')
    $('.person-tags').find('.person-tag').each((i, elem) ->
      tag = $(elem)
      if tag.data('tag-id') == tagId
        if tag.parent().children().length == 1
          tag.closest('.person-tags-category').remove()
          return false
        else
          tag.remove()
          return false
    )
}

$(document).on('click', 'a.person-tag-remove', app.PersonTags.removeTag)
$(document).on('click', '.person-tag-add', app.PersonTags.showForm)
$(document).on('submit', '.person-tags-add-form', -> app.PersonTags.loading(true); return true);
$(document).on('keydown', '.person-tags-add-form input#acts_as_taggable_on_tag_name', (event) ->
    event.keyCode == 27 && app.PersonTags.hideForm(); return true)
