# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte. This file is part of
#  hitobito_die_mitte and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_die_mitte.

class Payments::EbicsImportJob < RecurringJob
  run_every 1.day

  def perform_internal
    payment_provider_configs.find_each do |provider_config|
      Payments::EbicsImport.new(provider_config).run
    end
  end

  def payment_provider_configs
    PaymentProviderConfig.initialized
  end
end
