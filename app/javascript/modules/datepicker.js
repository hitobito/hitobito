// Copyright (c) 2026, Hitobito AG. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito.

window.App = window.App || {};

class AppDatepicker {
  constructor() {
    this.lastDate = null;
  }

  track(input, d, i) {
    this.lastDate = $(input).val();

    if (d !== i.lastVal) {
      $(input).change();
    }

    this.onChange(input, d);
  }

  show(input) {
    const self = this;
    let field = $(input);
    if (field.is('.icon-calendar')) {
      field = field.parent().siblings('.date');
    }

    // yearRange defines what years are selectable in the dropdown.
    // either relative to today's year ("-nn:+nn"), relative to the currently selected
    // year ("c-nn:c+nn"), absolute ("nnnn:nnnn").
    const yearRange = input.attributes.yearRange ? input.attributes.yearRange.value : $.datepicker._defaults.yearRange;
    const minDate = input.attributes.mindate ? new Date(input.attributes.mindate.value) : null;
    const maxDate = input.attributes.maxdate ? new Date(input.attributes.maxdate.value) : null;

    // Try to find the better matching fr-CH and it-CH
    const lang = $('html').attr('lang');
    const lang_ch = lang + '-CH';
    const options = $.extend({
        onSelect: function(d, i) { self.track(this, d, i); }
      },
      $.datepicker.regional[lang_ch] || $.datepicker.regional[lang],
      {
        minDate: minDate,
        maxDate: maxDate,
        changeMonth: true,
        changeYear: true,
        yearRange: yearRange,
        dateFormat: 'dd.mm.yy'
      }
    );

    field.datepicker(options);
    field.datepicker('show');

    if (this.lastDate && field.val() === "") {
      field.datepicker('setDate', this.lastDate);
      field.val(''); // user must confirm selection
    }
  }

  bind() {
    const self = this;
    $(document).on('click', 'input.date, .control-group .icon-calendar', function(e) {
      self.show(this);
    });
  }

  onChange(input, date) {
    // Manually trigger change event
    input.dispatchEvent(new Event("change"));
  }
}

new AppDatepicker().bind();
