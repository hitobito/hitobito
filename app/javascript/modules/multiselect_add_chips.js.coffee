#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# scope for global functions
app = window.App ||= {}

app.MultiselectAddChips = {
  selectValue: (e) ->
    e.preventDefault()
    id = e.target.dataset.addTo
    value = e.target.dataset.addValue
    app.tomSelects[id]?.addItem(value)

  clearValues: (e) ->
    e.preventDefault()
    id = e.target.dataset.clearValues
    app.tomSelects[id]?.clear()

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
$(document).on('ready', ->
  select = $("#group-filter-select")[0]
  if select
    app.MultiselectAddChips.showUnselected({target: select})
)
