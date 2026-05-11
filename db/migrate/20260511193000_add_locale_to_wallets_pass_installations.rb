# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class AddLocaleToWalletsPassInstallations < ActiveRecord::Migration[7.2]
  def change
    add_column :wallets_pass_installations, :locale, :string, null: false, default: "de"
  end
end
