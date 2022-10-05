#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

app.EventTags = {
  showForm: ->
    $('.event-tags-add-form').show();
    $('.event-tags-add-form input#acts_as_taggable_on_tag_name').val('').focus()
    $('.event-tag-add').hide();

  hideForm: ->
    $('.event-tags-add-form').hide();
    $('.event-tag-add').show();
    app.EventTags.loading(false)

  loading: (flag) ->
    $('.event-tags-add-form button').prop('disabled', flag)
    $('.event-tags-add-form button .spinner').toggle(flag);

  updateTags: (tags) ->
    $('.event-tags').replaceWith(tags)
    console.log('replacing with', tags)
    app.EventTags.hideForm()
    $('.event-tag-add').focus();

  removeTag: (domEvent) ->
    domEvent.preventDefault()
    tagId = $(domEvent.target).parent().data('tag-id')
    $('.event-tags').find('.event-tag').each((i, elem) ->
      tag = $(elem)
      if tag.data('tag-id') == tagId
        if tag.parent().children().length == 1
          tag.closest('.event-tags-category').remove()
          return false
        else
          tag.remove()
          return false
    )
}

$(document).on('click', 'a.event-tag-remove', app.EventTags.removeTag)
$(document).on('click', '.event-tag-add', app.EventTags.showForm)
$(document).on('submit', '.event-tags-add-form', -> app.EventTags.loading(true); return true);
$(document).on('keydown', '.event-tags-add-form input#acts_as_taggable_on_tag_name', (event) ->
    event.keyCode == 27 && app.EventTags.hideForm(); return true)
