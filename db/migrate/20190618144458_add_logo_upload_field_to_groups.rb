class AddLogoUploadFieldToGroups < ActiveRecord::Migration[4.2]
  def change
    add_column :groups, :logo, :string
  end
end
