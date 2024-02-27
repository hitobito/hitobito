# frozen_string_literal: true

#  Copyright (c) 2021-2024, Die Mitte. This file is part of
#  hitobito_die_mitte and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_die_mitte.

class Payments::EbicsImportJob < RecurringJob
  self.use_background_job_logging = true

  attr_reader :payments, :errors

  def initialize
    super
    @payments = Hash.new { |hash, key| hash[key] = [] }
    @errors = []
  end

  def perform_internal
    payment_provider_configs.find_each do |provider_config|
      Payments::EbicsImport.new(provider_config).run.each do |status, status_payments|
        @payments[status] += status_payments
      end
    rescue StandardError => e
      @errors << e
      error(self, e, payment_provider_config: provider_config)
    end
  end

  def payment_provider_configs
    PaymentProviderConfig.initialized
  end

  def next_run
    # Sets next run to 08:00 of next day
    Time.zone.tomorrow.at_beginning_of_day.change(hour: 8).in_time_zone
  end

  def log_results
    {
      imported_payments_count: payments['ebics_imported']&.size,
      without_invoice_count: payments['without_invoice']&.size,
      invalid_payments_count: payments['invalid']&.size,
      invalid_payments: payments['invalid']&.each_with_object({}) do |payment, invalid_payments|
        invalid_payments[payment.transaction_identifier] = payment.errors.messages
      end,
      errors: errors
    }
  end
end
