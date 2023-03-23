# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte. This file is part of
#  hitobito_die_mitte and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_die_mitte.

class Payments::EbicsImportJob < RecurringJob
  self.use_background_job_logging = true

  def initialize
    @imported_payments_count = 0
    super
  end

  def perform_internal
    payment_provider_configs.find_each do |provider_config|
      @imported_payments_count += Payments::EbicsImport.new(provider_config).run.size
    rescue StandardError => e
      error(self, e, payment_provider_config: provider_config)
      raise e # mustn't swallow error for BackgroundJobs::Logging to be able to log it
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
    { imported_payments_count: @imported_payments_count }
  end
end
