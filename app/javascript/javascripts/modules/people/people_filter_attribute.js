//  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
//  hitobito and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/hitobito/hitobito.

const app = window.App || {};

app.PeopleFilterAttribute = {
  remove: function(e) {
    $(e.target).closest('.people_filter_attribute_form').remove();
    e.preventDefault();
  },

  add: function(e) {
    if (e.target.value === '') return;
    const targetValue = e.target.value;
    const form = $('.people_filter_attribute_form_template').clone();

    app.PeopleFilterAttribute.duplicateAttributeForm(e, form);
    app.PeopleFilterAttribute.setAttributeNameTimestamp(targetValue, form);
    app.PeopleFilterAttribute.enableForm(form);
  },

  duplicateAttributeForm: function(e, form) {
    form.removeClass('people_filter_attribute_form_template');
    form.removeClass('d-none');
    form.find('.attribute_key_dropdown').val(e.target.value);
    form.find('.attribute_key_hidden_field').val(e.target.value);
    form.appendTo('#people_filter_attribute_forms');
    e.target.value = '';
  },

  setAttributeNameTimestamp: function(targetValue, form) {
    const time = new Date().getTime();

    app.PeopleFilterAttribute.renameAttributeName(form.find('.attribute_key_hidden_field'), time);
    app.PeopleFilterAttribute.renameAttributeName(form.find('.attribute_constraint_dropdown'), time);
    app.PeopleFilterAttribute.renameAttributeName(form.find('.attribute_value_input'), time, targetValue);
  },

  renameAttributeName: function(selector, time, targetValue) {
    const regex = /\[\d{13}\]/;

    //   Multiselects should not be renamed otherwise request will be forged wrongfully
    if (targetValue !== undefined && (targetValue === 'language' || targetValue === 'country')) {
      selector.each(function() {
        this.name = this.name.replace(regex, `[${time}]`);
      });
    } else {
      selector.attr('name', selector.attr('name').replace(regex, `[${time}]`));
    }
    // jquery datepicker needs a unique id to function properly
    selector.attr('id', selector.attr('id').replace(/_\d{13}_/, `_${time}_`));
  },

  enableForm: function(form) {
    const field = form.find('.attribute_key_hidden_field').attr('value');
    const type = form.closest('[data-types]').data('types')[field];

    if (field === 'years') {
      options = form.find('option[value=greater], option[value=smaller]');
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
    form.find('.' + type + '_field').removeAttr('disabled');
  },

  toggleValueVisibility: function(e) {
    const input = $(e.target).closest(".people_filter_attribute_form").find(".attribute_value_input");

    if (e.target.value === "blank") {
      input.addClass("invisible");
    } else {
      input.removeClass("invisible");
    }
  }
};

$(document).on('change', '#attribute_filter', app.PeopleFilterAttribute.add);
$(document).on('click', '.remove_filter_attribute', app.PeopleFilterAttribute.remove);
$(document).on('click', '.attribute_constraint_dropdown', app.PeopleFilterAttribute.toggleValueVisibility);

