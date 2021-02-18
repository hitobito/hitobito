class AddPictureToSettings < ActiveRecord::Migration[6.0]
  def change
    add_column :settings, :picture, :string
  end
end
