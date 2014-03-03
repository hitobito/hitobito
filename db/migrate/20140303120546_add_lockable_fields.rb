class AddLockableFields < ActiveRecord::Migration
  def change
    add_column :people, :failed_attempts, :integer, default: 0
    add_column :people, :locked_at, :datetime
  end

end
