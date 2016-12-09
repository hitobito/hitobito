class AddNicknameToLabelFormat < ActiveRecord::Migration
  def change
    add_column :label_formats, :nickname, :boolean, null: false, default: false
    add_column :label_formats, :pp_post, :string, default: nil
  end
end
