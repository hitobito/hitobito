#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class DestroyOrphanedEventAnswers < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      DELETE FROM "event_answers"
      WHERE "question_id" NOT IN (SELECT "id" FROM "event_questions");
    SQL
  end
end
