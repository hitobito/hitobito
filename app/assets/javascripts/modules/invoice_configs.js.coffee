#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

class app.InvoiceConfigs
  constructor: () ->

  showPaymentSlipSpecificAttributes: ->
    payment_slip = $('#invoice_config_payment_slip').find(":selected").val()
    beneficiary_control_group = $('#invoice_config_beneficiary').closest('.control-group')

    if payment_slip == 'ch_besr' || payment_slip == 'ch_bes'
      beneficiary_control_group.slideDown()
    else
      beneficiary_control_group.hide()

  bind: ->
    self = this
    $(document).on('change', '#invoice_config_payment_slip', (e) -> self.showPaymentSlipSpecificAttributes())
    $(document).on('turbolinks:load', (e) -> self.showPaymentSlipSpecificAttributes())

new app.InvoiceConfigs().bind()
