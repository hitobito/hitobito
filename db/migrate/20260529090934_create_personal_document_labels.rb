# Copyright (c) 2026. BienenSchweiz. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

class CreatePersonalDocumentLabels < ActiveRecord::Migration[8.0]
  def change
    create_table :personal_document_labels do |t|
      t.string :name, null: false

      t.timestamps
    end
  end
end
