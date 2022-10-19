// Copyright (c) 2022, Die Mitte Schweiz. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito.

// check app/helpers/dropdown/toggle_param_item.rb

const ToggleParamItem = {

  get toggleParamLinks() {
    return document
      .querySelectorAll('.dropdown-menu a.toggle-param');
  },
  
  toggleChecked(event) {
    // this prevents closing of drop down
    // when clicking on link
    event.stopPropagation();
    event.preventDefault();
    const link = event.target;
    const checkbox = link.querySelector('input[type="checkbox"]');
    checkbox.checked = !checkbox.checked;
    this.updateLinkParams(checkbox);
  },

  registerToggleParamLinks() {
    this.toggleParamLinks.forEach((toggleLink) => {
      toggleLink.addEventListener('click', (event) => {
        this.toggleChecked(event);
      })
    })
  },

  get toggleParamCheckboxes() {
    return document
      .querySelectorAll('.toggle-param input[type="checkbox"]');
  },

  linkItems(checkbox) {
    const parent = checkbox.closest('.dropdown-menu');
    return parent.querySelectorAll('a:not(.toggle-param)');
  },

  updateLinkParams(checkbox) {
    const paramName = checkbox.dataset.toggleParamId;
    const checked = checkbox.checked;
    this.linkItems(checkbox).forEach((link) => {
      let href = link.getAttribute('href');
      href = href.replace(`${paramName}=${!checked}`, `${paramName}=${checked}`)
      link.setAttribute('href', href);
    })
  },

  register() {
    this.registerToggleParamLinks();
  }
}

document.addEventListener("DOMContentLoaded",
    () => ToggleParamItem.register());
