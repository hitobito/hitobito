class RemoveAffiliateFieldsFromGroup < ActiveRecord::Migration
  def up
    remove_column :groups, :coach_id
    remove_column :groups, :advisor_id
  end

  def down
    add_column :groups, :coach_id, :integer
    add_column :groups, :advisor_id, :integer
  end
end
