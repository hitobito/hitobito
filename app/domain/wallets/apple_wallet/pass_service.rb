# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module Wallets
  module AppleWallet
    # Stub service for generating Apple Wallet (.pkpass) files.
    # Full implementation requires Apple Developer certificates and passkit signing.
    class PassService
      def initialize(pass, pass_installation:)
        @pass = pass
        @pass_installation = pass_installation
      end

      # Generates and returns the binary .pkpass archive.
      # Stub: raises NotImplementedError — the controller rescues StandardError
      # and redirects with a flash alert.
      def generate_pass
        raise NotImplementedError, "Wallets::AppleWallet::PassService is not yet implemented"
      end
    end
  end
end
