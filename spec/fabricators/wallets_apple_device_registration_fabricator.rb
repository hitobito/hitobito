# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

Fabricator(:wallets_apple_device_registration,
  class_name: "Wallets::AppleWallet::DeviceRegistration") do
  pass_installation { Fabricate(:wallets_pass_installation, wallet_type: :apple) }
  device_library_identifier { SecureRandom.hex(16) }
  push_token { SecureRandom.hex(32) }
end
