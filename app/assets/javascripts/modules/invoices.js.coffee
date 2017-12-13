#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

app.Invoices = {
  recalculate: (e) ->
    form = $('form[data-group')
    $.ajax(url: "#{form.data('group')}/invoice_list/new?#{form.serialize()}", dataType: 'script')
}

$(document).on('input', '#invoice_items_fields :input[data-recalculate]', app.Invoices.recalculate)
$(document).on('click', '#invoice_items_fields .remove_nested_fields', app.Invoices.recalculate)
