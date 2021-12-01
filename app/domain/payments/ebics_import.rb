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

    invoice_xmls = payment_provider.Z54(Time.zone.yesterday, Time.zone.today)

    invoice_xmls.flat_map { |xml| payments_from_xml(xml) }
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
      next unless in_payment_provider_config_layer?(payment.invoice&.group) && payment.save

      payment.invoice.invoice_list&.update_paid

      payment
    end.compact
  end

  def in_payment_provider_config_layer?(group)
    group == @payment_provider_config.invoice_config.group
  end
end
