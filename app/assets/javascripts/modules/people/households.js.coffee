- #  Copyright (c) 2012-2018, Pfadibewegung Schweiz. This file is part of
- #  hitobito and licensed under the Affero General Public License version 3
- #  or later. See the COPYING file at the top-level directory or at
- #  https://github.com/hitobito/hitobito.

app = window.App ||= {}

app.HouseHolds = {
  showPeopleTypeAhead: (e) ->
    form = $(e.target).closest('form')
    form.find(':input[name=q]').toggle()
    elem = form.find('.household_key_people')
    inputs = elem.find(":input[name='person[household_people_ids][]']")

    if elem.toggle().is(':visible')
      inputs.removeAttr('disabled')
    else
      inputs.attr('disabled', 'disabled')

  update: (e) ->
    data = JSON.parse(e)
    form = $('[data-household]').closest('form')
    query = form.find(':input[name^=person]').serialize()
    query += "&other_person_id=#{data.id}"
    action = form.attr('action') + "/households"
    $('[data-household]').load(action, query, app.HouseHolds.setupTypeahead)
    data.label

  setupTypeahead:  ->
    $(this).find('[data-provide=entity]').each(app.setupEntityTypeahead)

  showHouseholdAddressChangeWarning: ->
    if $('#household').is(':checked')
      $('.address-updated').remove()
      $('.updates-household-address').removeClass('hidden')

}
$(document).on('change', '[data-household] :checkbox[name=household]', app.HouseHolds.showPeopleTypeAhead)
$(document).on('input', '.address-input-fields', app.HouseHolds.showHouseholdAddressChangeWarning)
