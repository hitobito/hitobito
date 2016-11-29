class AddUserIdToLabelFormat < ActiveRecord::Migration
  def change
    add_column :label_formats, :user_id, :integer
  end
end
