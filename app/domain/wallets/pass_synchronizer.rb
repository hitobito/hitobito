# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module Wallets
  # Synchronizes a PassInstallation's validity state with the current Pass data.
  # Called after finding/creating a PassInstallation before dispatching to a wallet provider.
  class PassSynchronizer
    def initialize(pass_installation)
      @pass_installation = pass_installation
    end

    # Updates the installation's state based on the associated Pass.
    # Stub implementation — full logic to be added once wallet sync jobs are in place.
    def compute_validity!
      raise NotImplementedError, "Wallets::PassSynchronizer is not yet implemented"
    end
  end
end
