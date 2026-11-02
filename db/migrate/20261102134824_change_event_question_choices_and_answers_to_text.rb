#  Copyright (c) 2026, Cevi.DB Steuergruppe. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ChangeEventQuestionChoicesAndAnswersToText < ActiveRecord::Migration[8.0]
  def up
    change_column :event_question_translations, :choices, :text
    change_column :event_answers, :answer, :text
  end

  def down
    change_column :event_question_translations, :choices, :string
    change_column :event_answers, :answer, :string
  end
end
