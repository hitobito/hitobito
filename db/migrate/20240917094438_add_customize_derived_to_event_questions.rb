class AddCustomizeDerivedToEventQuestions < ActiveRecord::Migration[6.1]
  def change
    add_column :event_questions, :customize_derived, :boolean, default: false
  end
end
