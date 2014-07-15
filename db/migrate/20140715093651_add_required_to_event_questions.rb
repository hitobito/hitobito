class AddRequiredToEventQuestions < ActiveRecord::Migration
  def change
    add_column(:event_questions, :required, :boolean)
  end
end
