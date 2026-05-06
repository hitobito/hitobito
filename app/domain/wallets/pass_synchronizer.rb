#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module Wallets
  # Synchronizes a PassInstallation's validity state with the current Pass data.
  # Called after finding/creating a PassInstallation before dispatching to a wallet provider.
  class PassSynchronizer
    attr_reader :installation

    PASS_INSTALLATION_STATE_MAP = {
      eligible: :active,
      ended: :expired,
      revoked: :revoked
    }.freeze

    def initialize(pass_installation)
      @installation = pass_installation
    end

    # Sync all outdated pass installations with proper association preloading
    def self.sync_outdated!
      Wallets::PassInstallation.needs_sync.includes(:pass).find_each do |installation|
        new(installation).sync!
      rescue => e
        Rails.logger.error(
          "PassSynchronizer: Failed to sync PassInstallation##{installation.id}: #{e.message}"
        )
      end
    end

    # Full sync: recompute validity, push to provider, update state.
    def sync!
      installation.update!(state: installation_state)
      send(:"sync_#{installation.wallet_type}!")

      installation.update!(last_synced_at: Time.current, sync_error: nil, needs_sync: false)
    rescue => e
      installation.update!(sync_error: e.message)
      raise
    end

    # Mark for asynchronous processing by WalletSyncJob.
    def mark_for_sync!
      installation.update!(needs_sync: true)
    end

    def installation_state
      pass_state = installation.pass.state.to_sym
      installation.state = PASS_INSTALLATION_STATE_MAP.fetch(pass_state) do |key|
        raise "Unexpected pass state #{pass_state}"
      end
    end

    private

    def sync_google!
      service = Wallets::GoogleWallet::PassService.new(installation)
      if installation.revoked?
        service.revoke
      else
        service.create_or_update
      end
    end

    def sync_apple!
      AppleWallet::PushService.new(installation).send_update_notification
    end
  end
end
