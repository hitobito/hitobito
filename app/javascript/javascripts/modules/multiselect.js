// Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
// hitobito_sbv and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito.


function toggleActions(table) {
  const allElement = table.querySelector('thead input[name=all]') 
  const counts = checkedCounts(table)

  // toggle actions and select all checkbox
  allElement.checked = counts.checked > 0 && counts.unchecked === 0
  table.classList.toggle('actions-enabled', counts.checked > 0)

  // toggle extended select all checkbox
  const extendedAllElement = table.querySelector('thead input[name=extended_all]') 
  if(!allElement.checked && extendedAllElement?.checked) extendedAllElement.checked = false
  extendedAllElement.parentElement.classList.toggle('d-none', extendedAllElement.checked)

  // display count of selected elements
  const showCount =  extendedAllElement?.checked ? extendedAllElement.value : counts.checked
  table.querySelector('.multiselect .count').innerText = showCount
}

function setupMultiselectActions() {
  document.querySelectorAll('table[data-checkable=true]').forEach(table => {
    const actionsElement = document.querySelector("template#multiselectActions")?.content?.cloneNode(true)
    if(!actionsElement) return
      
    table.querySelector('thead tr').appendChild(actionsElement)
    table.querySelectorAll('input[type=checkbox]').forEach(checkbox => checkbox.addEventListener('change', () => toggleActions(table))) 
  })
}

function checkedCounts(table) {
  const checkboxElements = table.querySelectorAll('td:first-child input[type=checkbox]')

  return Array.from(checkboxElements).reduce((counts, checkboxElement) => {
    counts[checkboxElement.checked ? 'checked' : 'unchecked'] += 1;
    return counts
  }, { checked: 0, unchecked: 0 })
}

document.addEventListener('turbo:load', setupMultiselectActions)
