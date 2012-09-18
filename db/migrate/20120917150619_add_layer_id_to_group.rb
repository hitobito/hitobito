class AddLayerIdToGroup < ActiveRecord::Migration
  def up
    add_column :groups, :layer_group_id, :integer
    Group.find_each do |g|
      g.update_column(:layer_group_id, self.class.layer ? g.id : g.layer_groups.last.id)
    end
    add_index :groups, :layer_group_id
  end

  def down
    remove_column :groups, :layer_group_id
  end
end
