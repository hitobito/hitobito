#  frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreateAssignments < ActiveRecord::Migration[6.0]
  def change
    create_table :assignments do |t|
      t.belongs_to :person, null: false
      t.belongs_to :creator, null: false

      t.string :title, null: false
      t.text :description, null: false
      t.string :attachment_type
      t.integer :attachment_id

      t.date :read_at

      t.timestamps
    end
  end
end
