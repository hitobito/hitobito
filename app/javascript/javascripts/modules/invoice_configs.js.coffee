#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

class app.InvoiceConfigs
  constructor: () ->

  showPaymentSlipSpecificAttributes: ->
    beneficiary = $('#invoice_config_beneficiary').closest('.control-group')
    participant_number = $('#invoice_config_participant_number').closest('.control-group')
    participant_number_internal = $('#invoice_config_participant_number_internal').closest('.control-group')
    account_number = $('#invoice_config_account_number').closest('.control-group')

    if @isBank()
      beneficiary.slideDown()
    else
      beneficiary.hide()

    if @withReference()
      participant_number.slideDown()
    else
      participant_number.hide()

    if @isBank() and @withReference()
      participant_number_internal.slideDown()
    else
      participant_number_internal.hide()

    if @isNoPaymentSlip() || @isQr()
      account_number.hide()
    else
      account_number.show()

  bind: ->
    self = this
    $(document).on('change', '#invoice_config_payment_slip', (e) -> self.showPaymentSlipSpecificAttributes())
    $(document).on('turbolinks:load', (e) -> self.showPaymentSlipSpecificAttributes())

  isBank: ->
    val = $('#invoice_config_payment_slip').find(":selected").val()
    val == 'ch_besr' || val == 'ch_bes'

  withReference: ->
    val = $('#invoice_config_payment_slip').find(":selected").val()
    val == 'ch_besr' || val == 'ch_esr'

  isNoPaymentSlip: ->
    val = $('#invoice_config_payment_slip').find(":selected").val()
    val == 'no_ps'

  isQr: ->
    val = $('#invoice_config_payment_slip').find(":selected").val()
    val == 'qr'
new app.InvoiceConfigs().bind()
