#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddDonationConfirmationToMessages < ActiveRecord::Migration[6.0]
  def change
    add_column(:messages, :donation_confirmation, :boolean, default: false, null: false)
  end
end
