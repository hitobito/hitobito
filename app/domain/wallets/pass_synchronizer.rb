#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Wallets
  class PassSynchronizer
    attr_reader :pass_installation

    def initialize(pass_installation)
      @pass_installation = pass_installation
    end

    # Full sync: recompute validity, push to provider, update state.
    def sync!
      compute_validity!

      case pass_installation.wallet_type
      when "google" then sync_google!
      when "apple" then sync_apple!
      else raise "Unexpected wallet_type: #{pass_installation.wallet_type.inspect}"
      end

      pass_installation.update!(last_synced_at: Time.current, sync_error: nil)
    rescue => e
      pass_installation.update!(sync_error: e.message)
      raise
    end

    # Recompute validity from the PassMembership state.
    # Translates PassMembership state → PassInstallation state:
    #   :eligible     → :active
    #   :ended        → :expired
    #   :revoked      → :revoked
    def compute_validity!
      membership = pass_installation.pass_membership

      new_state = case membership.state
      when "eligible" then :active
      when "ended" then :expired
      when "revoked" then :revoked
      else raise "Unexpected membership state: #{membership.state.inspect}"
      end

      pass_installation.update!(state: new_state)
    end

    # Mark for asynchronous processing by WalletSyncJob.
    def mark_for_sync!
      pass_installation.update!(state: :pending_sync)
    end

    private

    def build_pass
      Pass.new(
        person: pass_installation.person,
        definition: pass_installation.pass_definition
      )
    end

    def sync_google!
      service = Wallets::GoogleWallet::PassService.new(build_pass)
      if pass_installation.revoked?
        service.revoke
      else
        service.create_or_update
      end
    end

    def sync_apple!
      # Phase 1 (WP 09): No push — iOS polls ~every 24h via WebServiceController.
      # PassInstallation state was already updated by compute_validity!.
      # The device fetches the updated .pkpass at its next polling interval.
      #
      # Phase 3 (WP 09a) will add:
      #   Wallets::AppleWallet::PushService.new(pass_installation).send_update_notification
    end
  end
end
