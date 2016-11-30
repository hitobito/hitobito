class AddNicknameToLabelFormat < ActiveRecord::Migration
  def change
    add_column :label_formats, :nickname, :boolean, null: false, default: false
  end
end
