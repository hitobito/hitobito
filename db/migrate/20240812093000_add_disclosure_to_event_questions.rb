class AddDisclosureToEventQuestions < ActiveRecord::Migration[6.1]
  def change
    add_column(:event_questions, :disclosure, :string, null: true)

    reversible do |direction|
      direction.up do
        connection.execute <<~SQL
          UPDATE event_questions SET disclosure = 'optional' WHERE disclosure IS NULL;
          UPDATE event_questions SET disclosure = 'required' WHERE required = TRUE;
        SQL
      end
      direction.down do
        connection.execute <<~SQL
          UPDATE event_questions SET required = FALSE WHERE disclosure = 'optional';
          UPDATE event_questions SET required = TRUE WHERE disclosure = 'required';
        SQL
      end
    end

    remove_column(:event_questions, :required, :boolean, default: false)
  end
end
