#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

app.Invoices = {
  recalculate: () ->
    form = document.querySelector('form[data-group]')
    return unless form
    formData = new FormData(form)
    serialized = new URLSearchParams(formData).toString()
    $.ajax(url: "#{form.dataset['group']}/invoices/recalculate/new?#{serialized}")
  setup: () ->
    document.querySelectorAll('form #invoice_items_fields input[data-recalculate]').forEach((input) ->
      input.addEventListener('input', app.Invoices.recalculate)
    )
    document.addEventListener("rails-nested-form:remove", app.Invoices.recalculate);
}

document.addEventListener("turbo:load", app.Invoices.setup);
document.addEventListener("rails-nested-form:add", app.Invoices.setup);
