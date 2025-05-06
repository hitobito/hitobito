# frozen_string_literal: true

#  Copyright (c) 2025-2025, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddBounces < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :bounce_sender, :string

    create_table :bounces do |t|
      t.string   :email, null: false, index: { unique: true }
      t.integer  :bounce_count, null: false, default: 0
      t.integer  :blocked_count, null: false, default: 0
      t.datetime :blocked_at
      t.integer  :mailing_list_ids, array: true

      t.timestamps
    end
  end
end
