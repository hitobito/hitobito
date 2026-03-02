#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class WalletSyncJob < RecurringJob
  run_every 15.minutes

  def perform_internal
    Wallets::PassInstallation.needs_sync.find_each do |installation|
      Wallets::PassSynchronizer.new(installation).sync!
    rescue => e
      Rails.logger.error("WalletSyncJob: Failed to sync PassInstallation##{installation.id}: #{e.message}")
    end
  end
end
