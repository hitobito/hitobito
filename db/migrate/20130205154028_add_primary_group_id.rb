class AddPrimaryGroupId < ActiveRecord::Migration
  def up
    add_column :people, :primary_group_id, :integer
    remove_column :people_filters, :kind
  end

  def down
    remove_column :people, :primary_group_id
    add_column :people_filters, :kind, :string
  end
end
