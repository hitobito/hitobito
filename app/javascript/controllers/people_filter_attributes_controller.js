// Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
// hitobito_sac_cas and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["select", "constraint", "trashIcons"]
  MULTISELECT_FIELDS = ["gender", "language", "country"]

  remove() {
    event.target.closest('.people_filter_attribute_form').remove();
    event.preventDefault()
  }

  add()  {
    if (event.target.value === '') return;
    const form = $('.people_filter_attribute_form_template').clone();

    this.duplicateAttributeForm(form);
    this.setAttributeNameTimestamp(form);
    this.enableForm(form);
  }

  duplicateAttributeForm(form) {
    form.removeClass('people_filter_attribute_form_template');
    form.removeClass('d-none');
    form.find('.attribute_key_dropdown').val(event.target.value);
    form.find('.attribute_key_hidden_field').val(event.target.value);
    form.appendTo('#people_filter_attribute_forms');
    event.target.value = '';
  }

  setAttributeNameTimestamp(form) {
    const time = new Date().getTime();

    this.renameAttributeName(form.find('.attribute_key_hidden_field'), time);
    this.renameAttributeName(form.find('.attribute_constraint_dropdown'), time);
    this.renameAttributeName(form.find('.attribute_value_input'), time);
  }

  renameAttributeName(selector, time) {
    const regex = /\[\d{13}\]/;
    //   Multiselects should not be renamed otherwise request will be forged wrongfully
    selector.attr('name', selector.attr('name').replace(regex, `[${time}]`));
    // jquery datepicker needs a unique id to function properly
    selector.attr('id', selector.attr('id').replace(/_\d{13}_/, `_${time}_`));
  }

  enableForm(form) {
    const field = form.find('.attribute_key_hidden_field').attr('value');
    const type = form.closest('[data-types]').data('types')[field];

    if (type === 'integer') {
      let options = form.find('option[value=greater], option[value=smaller]');
      if(field === "years") {
        options[0].remove()
        options[1].remove()
      }else {
        options[2].remove()
        options[3].remove()
      }
    }
    if (type !== 'integer') {
      form.find('option[value=greater], option[value=smaller]').remove()
    }
    if (type !== 'date') {
      form.find('option[value=before], option[value=after]').remove();
    }
    if (type !== 'string') {
      form.find('option[value=match], option[value=not_match]').remove();
    }
    form.find('.attribute_key_hidden_field').removeAttr('disabled');
    form.find('.attribute_constraint_dropdown').removeAttr('disabled');
    Array.from(form.find('.attribute_value_input:not(.' + type + '_field)')).forEach(function(element) {
      element.remove();
    });
    let valueElement = form.find('.' + type + '_field')[0]
    if(this.MULTISELECT_FIELDS.includes(type.replace(/_select$/, ""))) {
      valueElement.setAttribute("data-controller", "tom-select");
    }
    form.find('.' + type + '_field').removeAttr('disabled');
  }

  toggleValueVisibility(e) {
    const input = $(e.target).closest(".people_filter_attribute_form").find(".attribute_value_input");

    if (e.target.value === "blank") {
      input.addClass("invisible");
    } else {
      input.removeClass("invisible");
    }
  }

}
