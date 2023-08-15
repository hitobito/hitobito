# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class CreateMountedAttributes < ActiveRecord::Migration[6.1]
  def change
    create_table :mounted_attributes do |t|
      t.string :key, null: false
      t.integer :entry_id, null: false
      t.string :entry_type, null: false
      t.text :value

      t.timestamps
    end
  end
end
