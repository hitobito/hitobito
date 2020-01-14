class AddEventQuestionsAdmin < ActiveRecord::Migration[4.2]
  def change
    add_column :event_questions, :admin, :boolean, null: false, default: false
  end
end
