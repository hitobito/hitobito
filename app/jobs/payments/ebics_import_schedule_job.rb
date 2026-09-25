# frozen_string_literal: true

#  Copyright (c) 2024-2026, Hitobito AG. This file is part of
#  hitobito_die_mitte and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Payments::EbicsImportScheduleJob < RecurringJob
  def perform_internal
    payment_provider_pairs.each do |invoice_config_id, payment_provider|
      Payments::EbicsImportJob.new(invoice_config_id, payment_provider).enqueue!
    end
  end

  def next_run
    # Sets next run to 08:00 of next day
    Time.zone.tomorrow.at_beginning_of_day.change(hour: 8).in_time_zone
  end

  private

  def payment_provider_pairs
    PaymentProviderConfig.initialized.distinct.pluck(:invoice_config_id, :payment_provider)
  end
end
