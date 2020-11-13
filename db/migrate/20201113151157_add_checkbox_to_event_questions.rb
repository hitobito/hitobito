class AddCheckboxToEventQuestions < ActiveRecord::Migration[6.0]
  def change
    add_column :event_questions, :checkbox, :boolean, default: false, null: false
  end
end
