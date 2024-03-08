class AddEventTrainingDays < ActiveRecord::Migration[6.1]

  def up
    if column_exists?(:events, :training_days)
      change_column :events, :training_days, :decimal, precision: 5, scale: 2
    else
      add_column :events, :training_days, :decimal, precision: 5, scale: 2
    end

    add_column :qualification_kinds, :required_training_days, :decimal, precision: 5, scale: 2
  end

  def down
    remove_column :qualification_kinds, :required_training_days
    remove_column :events, :training_days
  end

end
