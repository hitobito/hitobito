#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito_dsj and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dsj.

app = window.App ||= {}

app.PersonTags = {
  showForm: ->
    $('.person-tags-add-form').show();
    $('.person-tags-add-form input#tag_name').val('').focus()
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
    app.PersonTags.hideError()

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

  showError: (error) ->
    app.PersonTags.loading(false)
    $('.person-tags-error').text(error).show()

  hideError: ->
    $('.person-tags-error').text('').hide()
}

$ ->
  $('.person-tag-add').on('click', app.PersonTags.showForm)
  $('.person-tags-add-form').on('submit', -> app.PersonTags.loading(true); return true);
  $('.person-tags-add-form input#tag_name').on('keypress', (event) ->
    event.keyCode == 27 && app.PersonTags.hideForm(); return true)
  $(document).on('click', 'a.person-tag-remove', app.PersonTags.removeTag)

