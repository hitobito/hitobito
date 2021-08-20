# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Payments::EbicsImport
  def initialize(payment_provider_config)
    @payment_provider_config = payment_provider_config
  end

  def run
    return [] unless @payment_provider_config.pending? || @payment_provider_config.registered?

    created_payments
  end

  private

  def created_payments
    payment_provider = PaymentProvider.new(@payment_provider_config)

    payment_provider.HPB

    invoice_xml = payment_provider.Z54

    payments_from_xml(invoice_xml)
  rescue Epics::Error::BusinessError => e
    case e.code
    when '090005'
      []
    else 
      raise e
    end
  end

  def payments_from_xml(xml)
    Invoice::PaymentProcessor.new(xml).payments.map do |payment|
      invoice = Invoice.find_by(reference: payment.reference,
                                group: @payment_provider_config.invoice_config.group)
      payment.invoice = invoice

      next unless payment.save

      invoice.invoice_list&.update_paid

      payment
    end.compact
  end
end
