// Copyright (c) 2024, Schweizer Wamderwege. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito.

function setupMultiselect() {
  document.querySelectorAll("table[data-checkable=true]").forEach((table) => {
    setupMultiselectCheckboxes(table);
    setupMultiselectActions(table);
  });

  // unfortunately, targets are not scoped to a table, so it just uses the first one
  const table = document.querySelector("table[data-checkable");
  setupMultiselectTargets(table);
}

function setupMultiselectTargets(table) {
  // swap href form data-checkable links
  document.querySelectorAll("a[data-checkable]:not(data-method)")
    .forEach((link) => link.addEventListener("click", () => link.href = buildLinkWithIds(link.href, table)));

  // swap href form data-checkable links with method
  document.querySelectorAll("form[data-checkable]").forEach((form) =>
    form.addEventListener("submit", () => {
      const ids = getSelectedIds(table);
      form.querySelector("input:input[data-checkable]").value = ids;
    }),
  );

  // tied to the use of jquery-ujs
  $.rails.href = (element) => {
    const href = element[0].href;
    if (!$(element).is("a[data-checkable]")) return href;

    return buildLinkWithIds(href, table);
  };
}

function setupMultiselectCheckboxes(table) {
  const checkboxElements = table.querySelectorAll("tbody input[type=checkbox]");
  const allCheckboxElement = table.querySelector("thead th:first-child input[type=checkbox]");

  // toggle all checkboxes when the «all» checkbox is changed
  allCheckboxElement?.addEventListener("click", () => {
    checkboxElements.forEach((checkboxElement) => checkboxElement.checked = allCheckboxElement.checked);
    toggleActions(table);
  });

  // hook into change of any checkbox
  checkboxElements.forEach((checkbox) => checkbox.addEventListener("change", () => toggleActions(table)));
}

function setupMultiselectActions(table) {
  // inject multiselect actions element into table
  const actionsElement = document.querySelector("template#multiselectActions")?.content?.cloneNode(true);
  if (!actionsElement) return;

  table.querySelector("thead tr").appendChild(actionsElement);
  table.querySelector("thead input[name=extended_all]")?.addEventListener("change", () => toggleActions(table));
}

function checkedCounts(table) {
  const checkboxElements = table.querySelectorAll("td:first-child input[type=checkbox]");

  return Array.from(checkboxElements).reduce(
    (counts, checkboxElement) => {
      counts[checkboxElement.checked ? "checked" : "unchecked"] += 1;
      return counts;
    }, { checked: 0, unchecked: 0 }
  );
}

function getSelectedIds(table) {
  const extendedAllElement = document.querySelector("thead input[name=extended_all]");
  if (extendedAllElement?.checked) return JSON.parse(extendedAllElement.dataset.ids);

  const checkboxElements = table.querySelectorAll("tbody input[type=checkbox]:checked");
  return Array.from(checkboxElements).map((checkboxElement) => checkboxElement.value);
}

function buildLinkWithIds(templateHref, table) {
  const ids = getSelectedIds(table);
  const separator = templateHref.indexOf("?") !== -1 ? "&" : "?";
  const match = window.location.href.match(/.+?\/(\d+)$/);
  return (templateHref + separator + (match ? `ids=${[match[1]]}&singular=true` : `ids=${ids}`));
}

function toggleActions(table) {
  const allElement = table.querySelector("thead input[name=all]");
  const counts = checkedCounts(table);

  // toggle actions and select all checkbox
  table.classList.toggle("actions-enabled", counts.checked > 0);
  if(allElement) allElement.checked = counts.checked > 0 && counts.unchecked === 0;

  // toggle extended select all checkbox
  const extendedAllElement = table.querySelector("thead input[name=extended_all]");
  if (extendedAllElement?.checked && !allElement?.checked) extendedAllElement.checked = false;
  const showExtendedAllElement = !extendedAllElement.checked && +extendedAllElement.value > counts.checked
  extendedAllElement?.parentElement?.classList?.toggle("d-none", !showExtendedAllElement);

  // display count of selected elements
  const showCount = extendedAllElement?.checked ? extendedAllElement.value : counts.checked;
  table.querySelector(".multiselect .count").innerText = showCount;
}

document.addEventListener("turbo:load", setupMultiselect);
