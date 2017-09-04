class AddEventQuestionsAdmin < ActiveRecord::Migration
  def change
    add_column :event_questions, :admin, :boolean, null: false, default: false
  end
end
