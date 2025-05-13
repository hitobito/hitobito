//  Copyright (c) 2025, Hitobito AG. This file is part of
//  hitobito and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/hitobito/hitobito.

const getVisibleFieldsCount = (wrapper) =>
  Array.from(wrapper.querySelectorAll(".fields"))
    .filter(el => getComputedStyle(el).display !== "none")
    .length;

const handleAddButtonVisibility = (assoc, limit) => {
  const wrapper = document.querySelector(`#${assoc}_fields`);
  if (!wrapper) return;
  const currentCount = getVisibleFieldsCount(wrapper);
  const addButton = wrapper.parentElement.querySelector(".add_nested_fields");

  if (limit != null) {
    if (currentCount >= limit) {
      addButton.classList.add("hidden");
    } else {
      addButton.classList.remove("hidden");
    }
  }
};

document.addEventListener('nested:fieldRemoved', (event) => {
  event.target.querySelectorAll('[required]').forEach(el => {
    el.removeAttribute('required');
  });
});

$(document).on('nested:fieldAdded', (event) => {
  const { association: assoc, limit } = event.target.dataset;
  handleAddButtonVisibility(assoc, parseInt(limit) || null);
});

$(document).on('nested:fieldRemoved', (event) => {
  const { association: assoc, limit } = event.target.parentElement.dataset;
  handleAddButtonVisibility(assoc, parseInt(limit) || null);
});

const initializeNestedFields = () => {
  document.querySelectorAll("[data-association]").forEach(field => {
    const { association: assoc, limit } = field.dataset;
    handleAddButtonVisibility(assoc, parseInt(limit) || null);
  });
};

$(document).on('turbo:load', initializeNestedFields);
window.addEventListener('turbo:render', initializeNestedFields);
