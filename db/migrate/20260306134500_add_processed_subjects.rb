#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddProcessedSubjects < ActiveRecord::Migration[8.0]
  def change
    create_table :invoice_run_processed_subjects do |t|
      t.belongs_to :subject, polymorphic: true, null: false
      t.belongs_to :item, null: false
      t.belongs_to :invoice, null:false
      t.index [:subject_id, :subject_type, :item_id, :invoice_id], unique: true, name: "index_processed_subjects"
    end
  end
end
