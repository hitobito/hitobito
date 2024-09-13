# frozen_string_literal: true

#  Copyright (c) 2024, Hitobito AG. This file is part of
#  hitobito_die_mitte and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Payments::EbicsImportScheduleJob < RecurringJob

  def perform_internal
    payment_provider_configs.find_each do |provider_config|
      Payments::EbicsImportJob.new(provider_config.id).enqueue!
    end
  end

  def next_run
    # Sets next run to 08:00 of next day
    Time.zone.tomorrow.at_beginning_of_day.change(hour: 8).in_time_zone
  end

  private

  def payment_provider_configs
    PaymentProviderConfig.initialized
  end

end
