#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# scope for global functions
app = window.App ||= {}

app.activateTomSelect = (i, element) ->
  new TomSelect('#' + element.id,
    plugins: [ 'remove_button' ]
    create: true
    onItemAdd: ->
      @setTextboxValue ''
      @refreshOptions()
      return
    render:
      option: (data, escape) ->
        '<div class="d-flex"><span>' + escape(data.value) + '</span></div>'
      item: (data, escape) ->
        '<div>' + escape(data.value) + '</div>'
  )

# only bind events for non-document elements in turbolinks:load
$(document).on('turbolinks:load', ->
  # enable tom-select
  $('.tom-select').each(app.activateTomSelect)
)
