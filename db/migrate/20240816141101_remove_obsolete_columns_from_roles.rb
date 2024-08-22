class RemoveObsoleteColumnsFromRoles < ActiveRecord::Migration[6.1]
  def change
    change_table :roles, bulk: true do |t|
      t.remove :deleted_at, type: :datetime
      t.remove :delete_on, type: :date
      t.remove :convert_on, type: :date
      t.remove :convert_to, type: :string
    end
  end
end
