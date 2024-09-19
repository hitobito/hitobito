class RevertChangeEventAnswersToJsonType < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL.squish
              UPDATE
                event_answers
              SET
                answer = TRIM(BOTH '"' FROM answer);
            SQL
  end

  def down
    execute <<~SQL.squish
              UPDATE
                event_answers
              SET
                answer = '"' || answer || '"';
            SQL
  end
end
