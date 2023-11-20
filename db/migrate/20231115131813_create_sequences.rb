# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class CreateSequences < ActiveRecord::Migration[6.1]

  def change
    create_table :sequences do |t|
      t.string :name, null: false, index: { unique: true }
      t.bigint :current_value, null: false, default: 0
    end
  end
end
