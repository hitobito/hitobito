class AddRequiredToEventQuestions < ActiveRecord::Migration
  def change
    add_column(:event_questions, :required, :boolean, null: false, default: false)
  end
end
