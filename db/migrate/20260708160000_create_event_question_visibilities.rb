# frozen_string_literal: true

#  Copyright (c) 2026, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreateEventQuestionVisibilities < ActiveRecord::Migration[8.0]
  def up
    create_table :event_question_visibilities do |t|
      t.belongs_to :question, foreign_key: false
      t.string :role_type, null: false
    end

    add_index :event_question_visibilities, [:question_id, :role_type],
      unique: true, name: "idx_event_question_visibilities_unique"
  end

  def down
    drop_table :event_question_visibilities
  end
end
