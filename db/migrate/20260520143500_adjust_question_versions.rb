#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AdjustQuestionVersions < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      UPDATE versions
      SET object_changes =
      REPLACE(
        REPLACE(
          REPLACE(
            REPLACE(
              REPLACE(
                REPLACE(object_changes,
                  E'disclosure:\n- \n- optional\n', ''),
                E'disclosure:\n- \n- required\n', E'required:\n- false\n- true\n'),
              E'disclosure:\n- optional\n- required\n', E'required:\n- false\n- true\n'),
            E'disclosure:\n- hidden\n- required\n', E'required:\n- false\n- true\n'),
          E'disclosure:\n- required\n- optional\n', E'required:\n- true\n- false\n'),
        E'disclosure:\n- required\n- hidden\n', E'required:\n- true\n- false\n')
      WHERE item_type = 'Event::Question';
    SQL
  end

  def down
    # not possible anymmore
  end
end
