# Copyright (c) 2026. BienenSchweiz. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

class CreatePersonalDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :personal_documents do |t|
      t.belongs_to :person, foreign_key: true, null: false
      t.belongs_to :personal_document_label, foreign_key: false
      t.belongs_to :author, foreign_key: { to_table: :people }, null: false

      t.timestamps
    end
  end
end
