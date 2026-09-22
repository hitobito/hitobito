# frozen_string_literal: true

#  Copyright (c) 2021-2026, Die Mitte. This file is part of
#  hitobito_die_mitte and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_die_mitte.

class Payments::EbicsImportJob < BaseJob
  self.parameters = [:invoice_config_id, :payment_provider]
  self.use_background_job_logging = true

  def initialize(invoice_config_id, payment_provider)
    super()
    @invoice_config_id = invoice_config_id
    @payment_provider = payment_provider
  end

  def perform # rubocop:todo Metrics/AbcSize
    @used_config = primary_config
    create_start_log
    import_with_fallback.each do |status, status_payments|
      payments[status] += status_payments
    end
    create_success_log
  rescue Invoice::PaymentProcessor::ProcessError => process_error
    errors << process_error.error
    create_error_log(process_error.error, process_error.xml)
    error(self, process_error.error, payment_provider_config: @used_config)
  rescue StandardError => error
    errors << error
    create_error_log(error)
    error(self, error, payment_provider_config: @used_config)
  end

  def log_results
    {
      imported_payments_count: payments["ebics_imported"]&.size,
      without_invoice_count: payments["without_invoice"]&.size,
      invalid_payments_count: payments["invalid"]&.size,
      invalid_payments: payments["invalid"]&.each_with_object({}) do |payment, invalid_payments|
        invalid_payments[payment.transaction_identifier] = payment.errors.messages
      end,
      errors: errors
    }
  end

  def create_start_log
    create_log_entry(level: "info",
      message: "Starting Ebics payment import")
  end

  def create_success_log
    create_log_entry(level: "info",
      message: "Successfully imported #{payments.values.flatten.size} payments",
      payload: log_results)
  end

  def create_error_log(error, xml = nil)
    create_log_entry(level: "error",
      message: "Could not import payment from Ebics",
      payload: {error: error.detailed_message},
      xml: xml)
  end

  def create_log_entry(level: "", message: "", payload: nil, xml: nil)
    log = HitobitoLogEntry.create!(
      level: level,
      subject: @used_config,
      category: "ebics",
      message: message,
      payload: payload
    )

    if xml.present?
      log.attachment.attach({io: StringIO.new(xml),
                              content_type: "application/xml",
                              filename: "log_attachment_#{log.id}"})
    end

    log
  end

  # Tries the primary (preferably EBICS 3.0) config first; on any EBICS-level error, if a
  # second config exists for this invoice_config/payment_provider pair, retries with that
  # one. Errors unrelated to EBICS itself (e.g. payment xml processing) are not retried.
  def import_with_fallback
    Payments::EbicsImport.new(primary_config).run
  rescue Epics::Error, PaymentProviders::EbicsError => e
    raise e unless fallback_config

    @used_config = fallback_config
    Payments::EbicsImport.new(fallback_config).run
  end

  def primary_config
    payment_provider_configs.first
  end

  def fallback_config
    payment_provider_configs.second
  end

  # Ordered by legacy_25_ebics ascending, so EBICS 3.0 (false) comes before 2.5 (true) when
  # both exist. When only one config exists (either version), it is always primary_config,
  # with no fallback_config to retry with.
  def payment_provider_configs
    @payment_provider_configs ||= PaymentProviderConfig.initialized
      .where(invoice_config_id: @invoice_config_id, payment_provider: @payment_provider)
      .list.to_a
  end

  def payments
    @payments ||= Hash.new { |hash, key| hash[key] = [] }
  end

  def errors
    @errors ||= []
  end
end
