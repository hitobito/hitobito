- #  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
- #  hitobito and licensed under the Affero General Public License version 3
- #  or later. See the COPYING file at the top-level directory or at
- #  https://github.com/hitobito/hitobito.

app = window.App ||= {}

app.Family = {
  showPeopleTypeAhead: (e) ->
    form = $(e.target).closest('form')
    form.find(':input[name=family_query]').toggle()
    elem = form.find('.family_key_members')
    inputs = elem.find(":input[name='person[family_members_ids][]']")

    if elem.toggle().is(':visible')
      inputs.removeAttr('disabled')
    else
      inputs.attr('disabled', 'disabled')

  update: (e) ->
    data = JSON.parse(e)
    form = $('[data-family]').closest('form')
    query = form.find(':input[name^=person]').serialize()
    query += "&other_person_id=#{data.id}"
    action = form.attr('action') + "/family"
    $('[data-family]').load(action, query, app.Family.setupTypeahead)
    data.label

  setupTypeahead:  ->
    $(this).find('[data-provide=entity]').each(app.setupEntityTypeahead)

  # showFamilyAddressChangeWarning: ->
  #   if $('#family').is(':checked')
  #     $('.address-updated').remove()
  #     $('.updates-family-address').removeClass('hidden')

}
$(document).on('change', '[data-family] :checkbox[name=family]', app.Family.showPeopleTypeAhead)
# $(document).on('input', '.address-input-fields', app.Family.showFamilyAddressChangeWarning)
