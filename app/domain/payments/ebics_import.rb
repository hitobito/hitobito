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

    created_payments.group_by(&:status)
  end

  private

  def created_payments
    payment_provider = PaymentProvider.new(@payment_provider_config)

    payment_provider.HPB

    invoice_xmls = payment_provider.Z54(3.days.ago.to_date, Time.zone.today)

    invoice_xmls.flat_map { |xml| payments_from_xml(xml) }
  rescue Epics::Error::BusinessError => e
    case e.code
    when '090005' # EBICS_NO_DOWNLOAD_DATA_AVAILABLE
      {}
    else
      raise e
    end
  end

  def payments_from_xml(xml)
    Invoice::PaymentProcessor.new(xml).payments.map do |payment|
      if payment.invoice.present?
        payment.status = :ebics_imported

        next unless in_payment_provider_config_layer?(payment.invoice&.group)
      else
        payment.status = :without_invoice
      end

      if payment.save
        payment.invoice&.invoice_list&.update_paid
      else
        payment.status = :invalid
      end

      payment
    end.compact
  end

  def in_payment_provider_config_layer?(group)
    group == @payment_provider_config.invoice_config.group
  end
end
