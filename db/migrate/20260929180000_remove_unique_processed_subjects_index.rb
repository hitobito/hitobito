# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RemoveUniqueProcessedSubjectsIndex < ActiveRecord::Migration[8.0]
  def up
    remove_index :invoice_run_processed_subjects, name: "index_unique_processed_subjects"
  end

  def down
    # Existing rows may violate the uniqueness, so they have to go.
    InvoiceRun::ProcessedSubject.delete_all

    add_index :invoice_run_processed_subjects, [:subject_type, :subject_id, :template_item_id],
      name: "index_unique_processed_subjects", unique: true
  end
end
