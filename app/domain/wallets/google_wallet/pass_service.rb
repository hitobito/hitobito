# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module Wallets
  module GoogleWallet
    # Stub service for generating Google Wallet pass save URLs.
    # Full implementation requires Google Wallet API credentials and JWT signing.
    class PassService
      def initialize(pass_installation)
        @pass_installation = pass_installation
      end

      # Returns a Google Wallet "Add to Google Wallet" save URL.
      # Stub: raises NotImplementedError — the controller rescues StandardError
      # and redirects with a flash alert.
      def save_url
        raise NotImplementedError, "Wallets::GoogleWallet::PassService is not yet implemented"
      end
    end
  end
end
