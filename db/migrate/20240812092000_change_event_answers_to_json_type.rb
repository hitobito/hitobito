class ChangeEventAnswersToJsonType < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL.squish
              UPDATE
                event_answers
              SET
                answer = '"' || answer || '"';
            SQL

    change_column :event_answers, :answer, 'json USING answer::json'
  end

  def down
    change_column :event_answers, :answer, :string
  end

end
