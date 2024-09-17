# frozen_string_literal: true

#  Copyright (c) 2021-2024, Die Mitte. This file is part of
#  hitobito_die_mitte and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_die_mitte.

class Payments::EbicsImportJob < BaseJob
  self.parameters = [:payment_provider_config_id]
  self.use_background_job_logging = true

  def initialize(payment_provider_config_id)
    super()
    @payment_provider_config_id = payment_provider_config_id
  end

  def perform
    create_start_log
    Payments::EbicsImport.new(payment_provider_config).run.each do |status, status_payments|
      payments[status] += status_payments
    end
    create_success_log
  rescue Invoice::PaymentProcessor::ProcessError => process_error
    errors << process_error.error
    create_error_log(process_error.error, process_error.xml)
    error(self, process_error.error, payment_provider_config: payment_provider_config)
  rescue StandardError => error
    errors << error
    create_error_log(error)
    error(self, error, payment_provider_config: payment_provider_config)
  end

  def payment_provider_configs
    PaymentProviderConfig.initialized
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
    # Hitobito.logger.log()
    HitobitoLogEntry.create!(
      level: "info",
      subject: payment_provider_config,
      category: "ebics",
      message: "Starting Ebics payment import"
    )
  end

  def create_success_log
    HitobitoLogEntry.create!(
      level: "info",
      subject: payment_provider_config,
      category: "ebics",
      message: "Successfully imported #{payments.size} payments",
      payload: log_results
    )
  end

  def create_error_log(error, xml = nil)
    log_entry = HitobitoLogEntry.create!(
      level: "error",
      subject: payment_provider_config,
      category: "ebics",
      message: "Could not import payment from Ebics",
      payload: { error: error.detailed_message }
    )

    if xml.present?
      log_entry.attachment.attach({ io: StringIO.new(xml), content_type: 'application/xml', filename: "log_attachment_#{log_entry.id}" })
    end
  end

  def payment_provider_config
    @payment_provider_config ||= PaymentProviderConfig.find(@payment_provider_config_id)
  end

  def payments
    @payments ||= Hash.new { |hash, key| hash[key] = [] }
  end

  def errors
    @errors ||= []
  end
end
