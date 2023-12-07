#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# scope for global functions
app = window.App ||= {}

app.MultiselectAddChips = {
  selectValue: (e) ->
    e.preventDefault()
    select = $("##{e.target.dataset.addTo}")
    value = e.target.dataset.addValue
    currentValue = select.val() || []
    select.val(currentValue.concat([value])).trigger("chosen:updated")

  clearValues: (e) ->
    e.preventDefault()
    select = $("##{e.target.dataset.clearValues}")
    select.val([]).trigger("chosen:updated")

  showUnselected: (e) ->
    selectId = e.target.id
    selected = $(e.target).val() || []
    chips = $("button[data-add-to=#{selectId}]")
    chips.hide()
    chips.filter(-> !selected.includes(this.dataset.addValue)).show()
    if selected.length == 0
      $("button[data-clear-values=#{selectId}]").hide()
    else
      $("button[data-clear-values=#{selectId}]").show()
}

$(document).on('click', 'button[data-add-to]', app.MultiselectAddChips.selectValue)
$(document).on('click', 'button[data-clear-values]', app.MultiselectAddChips.clearValues)
$(document).on('change', '.form-select', app.MultiselectAddChips.showUnselected)
$(document).on('chosen:updated', '.form-select', app.MultiselectAddChips.showUnselected)
$(document).on('chosen:ready', app.MultiselectAddChips.showUnselected)
