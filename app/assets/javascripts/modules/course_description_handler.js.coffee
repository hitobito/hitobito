#  Copyright (c) 2015 Pro Natura Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

app.EventDescription = {
  getDescription: ->
    that = app.EventDescription
    id = $(this).val()
    that.insertOrAsk(id)
  
  insertOrAsk: (id) ->
    if this.descriptionEmpty()
      this.fillDescription(id)
    else
      this.enableDefaultLink(id)

  getDescriptionForId: (id) ->
    $('.default-description[data-kind=' + id + ']').text().trim()

  fillDescription: (id) ->
    textarea = this.elements().textarea
    oldText = textarea.val()
    newText = this.getDescriptionForId(id)

    spacer = if oldText == "" then "" else " "
    textarea.val(oldText + spacer + newText)

  descriptionEmpty: ->
    return this.elements().textarea.val() == ""
  
  elements: ->
    {
      descriptionLink: $('.standard-description-link'),
      textarea: $('textarea#event_description')
    }

  enableDefaultLink: (id) ->
    this.showLink()
    link = this.elements().descriptionLink

    that = this
    
    link.off('click')
    link.click (e) ->
      e.preventDefault()
      that.fillDescription(id)
      that.hideLink()
  
  hideLink: ->
    this.elements().descriptionLink.parents('.controls').hide();
  
  showLink: ->
    this.elements().descriptionLink.parents('.controls').show();
}

$(document).on('change', 'select#event_kind_id', app.EventDescription.getDescription)
