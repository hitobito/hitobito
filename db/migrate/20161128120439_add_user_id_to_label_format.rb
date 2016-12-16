class AddUserIdToLabelFormat < ActiveRecord::Migration
  def change
    add_column :label_formats, :user_id, :integer
    add_column :people, :show_global_label_formats, :boolean, default: true
  end
end
