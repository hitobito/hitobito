# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreateCorsOrigins < ActiveRecord::Migration[6.0]
  def change
    create_table :cors_origins do |t|
      t.references :auth_method, polymorphic: true
      t.string :origin, null: false
    end

    add_index :cors_origins, :origin
  end
end
