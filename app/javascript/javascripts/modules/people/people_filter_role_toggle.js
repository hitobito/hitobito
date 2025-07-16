function showAllGroups(radio) {
  if (radio.checked) {
    $('.layer, .group').slideDown();
  }
}

function showSameLayerGroups(radio) {
  if (radio.checked) {
    let selectorToHide = $('.layer')
    removeSelectedItems(selectorToHide)
    $('.same-layer, .same-group').show();
    $('.layer, .group').show();
    selectorToHide.hide();
    $('.layer:not(.same-layer) select option').prop('selected', false);
    $('.same-layer', '.group').show();
    $('.same-layer .group').slideDown();
  }
}

function showSameGroup(radio) {
  if (radio.checked) {
    let selectorsToHide = $('.layer, .group')
    removeSelectedItems(selectorsToHide)
    selectorsToHide.hide();
    $('.layer:not(.same-layer) select option, .group:not(.same-group) select option').prop('selected', false);
    $('.same-layer, .same-group').show();
  }
}

function removeSelectedItems(items) {
  const roleSelect = $('#role-select')
  const tomselect = roleSelect[0]?.tomselect;

  if (roleSelect.length > 0 && tomselect) {
    const values = getValues(items);

    for (const value of values) {
      if (tomselect.items.includes(value)) {
        tomselect.removeItem(value);
      }
    }
  }
}

function getValues(items) {
  values = [];
  for (item of items) {
    values.push(item.getAttribute('data-value'));
  }
  return values;
}

$(document).on('change', 'input#range_deep', (e) => showAllGroups(e.target));
$(document).on('change', 'input#range_layer', (e) => showSameLayerGroups(e.target));
$(document).on('change', 'input#range_group', (e) => showSameGroup(e.target));

$(document).on('turbo:load', () => {
  $('input#range_deep').each((i, e) => showAllGroups(e));
  $('input#range_layer').each((i, e) => showSameLayerGroups(e));
  $('input#range_group').each((i, e) => showSameGroup(e));
});
