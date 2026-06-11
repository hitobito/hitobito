class AddTemplateIdToEventQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :event_questions, :template_id, :integer, null: true
  end
end
