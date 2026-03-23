#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module Wallets
  # Synchronizes a PassInstallation's validity state with the current Pass data.
  # Called after finding/creating a PassInstallation before dispatching to a wallet provider.
  class PassSynchronizer
    attr_reader :pass_installation

    def initialize(pass_installation)
      @pass_installation = pass_installation
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
      compute_validity!

      case pass_installation.wallet_type
      when "google" then sync_google!
      when "apple" then sync_apple!
      else raise "Unexpected wallet_type: #{pass_installation.wallet_type.inspect}"
      end

      pass_installation.update!(last_synced_at: Time.current, sync_error: nil, needs_sync: false)
    rescue => e
      pass_installation.update!(sync_error: e.message)
      raise
    end

    # Recompute validity from the Pass state.
    # Translates Pass state → PassInstallation state
    def compute_validity!
      pass_state = pass_installation.pass.state

      new_state = case pass_state
      when "eligible" then :active
      when "ended" then :expired
      when "revoked" then :revoked
      else raise "Unexpected pass state: #{pass_state.inspect}"
      end

      pass_installation.update!(state: new_state)
    end

    # Mark for asynchronous processing by WalletSyncJob.
    def mark_for_sync!
      pass_installation.update!(needs_sync: true)
    end

    private

    def sync_google!
      service = Wallets::GoogleWallet::PassService.new(pass_installation)
      if pass_installation.revoked?
        service.revoke
      else
        service.create_or_update
      end
    end

    def sync_apple!
      AppleWallet::PushService.new(pass_installation).send_update_notification
    end
  end
end
