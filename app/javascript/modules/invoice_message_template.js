// Copyright (c) 2026, Hitobito AG. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito.

document.addEventListener('change', function(event) {
  if (!event.target.matches('[data-message-template-id]')) return

  const selectedOption = event.target.selectedOptions[0];
  const form = event.target.closest('form');
  form.querySelectorAll('[data-message-template-target]').forEach(targetElement => {
    const attr = targetElement.dataset.messageTemplateTarget
    targetElement.value = selectedOption?.dataset[attr] || ''
    fillTranslatedInputs(form, targetElement, attr, selectedOption)
  })
})

function fillTranslatedInputs(form, targetElement, attr, selectedOption) {
  form.querySelectorAll(`[name^="${targetElement.name.replace(/\]$/, '_')}"]`).forEach(input => {
    const locale = input.name.slice(targetElement.name.length, -1)
    input.value = selectedOption?.dataset[`${attr}${locale.charAt(0).toUpperCase()}${locale.slice(1)}`] || ''
  })
}
