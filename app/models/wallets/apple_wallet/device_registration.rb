#  Copyright (c) 2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Wallets::AppleWallet::DeviceRegistration < ActiveRecord::Base
  belongs_to :pass_installation, class_name: "Wallets::PassInstallation"

  validates :device_library_identifier, presence: true,
    uniqueness: {scope: :pass_installation_id}
  validates :push_token, presence: true
end
