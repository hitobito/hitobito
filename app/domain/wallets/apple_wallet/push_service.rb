#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Wallets
  module AppleWallet
    class PushService
      attr_reader :pass_installation

      def initialize(pass_installation)
        @pass_installation = pass_installation
      end

      def send_update_notification
        # No-op implementation for now
        # iOS devices poll ~every 24h via WebServiceController
        # The device fetches the updated .pkpass at its next polling interval
        #
        # Future implementation will send APNs push notifications to trigger
        # immediate pass updates on the device
      end
    end
  end
end
