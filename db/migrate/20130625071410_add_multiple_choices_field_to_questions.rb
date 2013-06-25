class AddMultipleChoicesFieldToQuestions < ActiveRecord::Migration
  def change
    add_column(:event_questions, :multiple_choices, :boolean, default: false)
  end
end
